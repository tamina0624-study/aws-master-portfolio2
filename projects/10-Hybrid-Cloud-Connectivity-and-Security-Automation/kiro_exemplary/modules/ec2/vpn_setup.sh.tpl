#!/bin/bash
set -e

###############################################################################
# VPNルーター (strongSwan + FRR) 自動構築スクリプト
###############################################################################

# 1. パッケージインストール
apt-get update
apt-get install -y strongswan strongswan-swanctl charon-systemd frr

# 自身のプライベートIPを動的取得
LOCAL_PRIVATE_IP=$(hostname -I | awk '{print $1}')

# 2. swanctl.conf (IPsec設定)
cat <<EOF > /etc/swanctl/swanctl.conf
connections {
    # --- Tunnel 1 ---
    aws-tunnel-1 {
        local_addrs  = $LOCAL_PRIVATE_IP
        remote_addrs = ${tun1_outside_ip}
        version = 1
        proposals = aes128-sha1-modp1024,aes256-sha256-modp2048,default
        keyingtries = 0
        local {
            auth = psk
            id = ${onprem_public_ip}
        }
        remote {
            auth = psk
            id = ${tun1_outside_ip}
        }
        children {
            vti-t1 {
                local_ts  = 0.0.0.0/0
                remote_ts = 0.0.0.0/0
                esp_proposals = aes128-sha1-modp1024,aes256-sha256-modp2048,default
                mark_in = 10
                mark_out = 10
                mode = tunnel
                start_action = start
            }
        }
    }

    # --- Tunnel 2 ---
    aws-tunnel-2 {
        local_addrs  = $LOCAL_PRIVATE_IP
        remote_addrs = ${tun2_outside_ip}
        version = 1
        proposals = aes128-sha1-modp1024,aes256-sha256-modp2048,default
        keyingtries = 0
        local {
            auth = psk
            id = ${onprem_public_ip}
        }
        remote {
            auth = psk
            id = ${tun2_outside_ip}
        }
        children {
            vti-t2 {
                local_ts  = 0.0.0.0/0
                remote_ts = 0.0.0.0/0
                esp_proposals = aes128-sha1-modp1024,aes256-sha256-modp2048,default
                mark_in = 11
                mark_out = 11
                mode = tunnel
                start_action = start
            }
        }
    }
}

secrets {
    ike-aws-t1 {
        id-1 = ${onprem_public_ip}
        id-2 = ${tun1_outside_ip}
        secret = ${tun1_psk}
    }
    ike-aws-t2 {
        id-1 = ${onprem_public_ip}
        id-2 = ${tun2_outside_ip}
        secret = ${tun2_psk}
    }
}
EOF

# 3. VTIインターフェース作成
ip tunnel add vti-t1 local $LOCAL_PRIVATE_IP remote ${tun1_outside_ip} mode vti key 10
ip tunnel add vti-t2 local $LOCAL_PRIVATE_IP remote ${tun2_outside_ip} mode vti key 11

ip addr add ${tun1_inside_cgw_ip}/30 dev vti-t1
ip addr add ${tun2_inside_cgw_ip}/30 dev vti-t2

ip link set vti-t1 up
ip link set vti-t2 up

ip route add ${tun1_inside_cidr_block} dev vti-t1 table 220
ip route add ${tun2_inside_cidr_block} dev vti-t2 table 220

sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.ip_forward=1

# 4. FRR (BGP) 設定
sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons

cat <<EOF > /etc/frr/frr.conf
frr version 8.1
frr defaults traditional
hostname $(hostname)
log syslog informational
!
router bgp ${onprem_bgp_asn}
 bgp router-id ${tun1_inside_cgw_ip}
 timers bgp 6 20
 neighbor ${tun1_inside_vgw_ip} remote-as ${aws_bgp_asn}
 neighbor ${tun1_inside_vgw_ip} update-source ${tun1_inside_cgw_ip}
 neighbor ${tun2_inside_vgw_ip} remote-as ${aws_bgp_asn}
 neighbor ${tun2_inside_vgw_ip} update-source ${tun2_inside_cgw_ip}
 !
 address-family ipv4 unicast
  network ${tun1_inside_cidr_block}
  network ${tun2_inside_cidr_block}
  redistribute connected
  neighbor ${tun1_inside_vgw_ip} soft-reconfiguration inbound
  neighbor ${tun1_inside_vgw_ip} route-map ALLOW_ALL in
  neighbor ${tun1_inside_vgw_ip} route-map ALLOW_ALL out
  neighbor ${tun2_inside_vgw_ip} soft-reconfiguration inbound
  neighbor ${tun2_inside_vgw_ip} route-map ALLOW_ALL in
  neighbor ${tun2_inside_vgw_ip} route-map ALLOW_ALL out
 exit-address-family
exit
!
ip prefix-list ANY seq 5 permit 0.0.0.0/0 le 32
!
route-map ALLOW_ALL permit 10
 match ip address prefix-list ANY
exit
!
line vty
!
EOF

# 5. サービス起動
systemctl enable strongswan-swanctl
systemctl restart strongswan-swanctl
systemctl enable frr
systemctl restart frr

echo "VPN Router setup completed successfully."
