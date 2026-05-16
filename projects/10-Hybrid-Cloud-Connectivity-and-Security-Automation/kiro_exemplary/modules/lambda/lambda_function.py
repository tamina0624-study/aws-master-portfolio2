"""
GuardDuty Finding → WAF deny-ipset 自動更新 Lambda関数

GuardDutyが検知した攻撃元IPアドレスをWAF v2のdeny-ipsetに自動追加し、
以降のアクセスをブロックする自律防御機能。
"""

import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def extract_attacker_ips(event: dict) -> set:
    """
    GuardDuty Findingイベントから攻撃元IPアドレスを抽出する。
    複数のアクションタイプに対応。
    """
    ips = set()
    detail = event.get("detail", {})
    service = detail.get("service", {})
    action = service.get("action", {})

    # portProbeAction
    port_probe = action.get("portProbeAction", {})
    for probe in port_probe.get("portProbeDetails", []):
        ip = probe.get("remoteIpDetails", {}).get("ipAddressV4")
        if ip:
            ips.add(ip)

    # networkConnectionAction
    net_conn = action.get("networkConnectionAction", {})
    ip = net_conn.get("remoteIpDetails", {}).get("ipAddressV4")
    if ip:
        ips.add(ip)

    # awsApiCallAction
    api_call = action.get("awsApiCallAction", {})
    ip = api_call.get("remoteIpDetails", {}).get("ipAddressV4")
    if ip:
        ips.add(ip)

    # dnsRequestAction (DNS exfiltration等)
    dns_req = action.get("dnsRequestAction", {})
    ip = dns_req.get("remoteIpDetails", {}).get("ipAddressV4")
    if ip:
        ips.add(ip)

    return ips


def lambda_handler(event, context):
    """
    メインハンドラー: GuardDuty Finding → deny-ipset更新
    """
    waf = boto3.client("wafv2")

    ip_set_id = os.environ.get("WAFV2_IP_SET_ID")
    ip_set_name = os.environ.get("WAFV2_IP_SET_NAME", "deny-ipset")
    scope = os.environ.get("WAFV2_SCOPE", "REGIONAL")

    if not ip_set_id:
        logger.error("WAFV2_IP_SET_ID environment variable is not set")
        return {"status": "error", "reason": "WAFV2_IP_SET_ID not configured"}

    # 現在のIPセットを取得
    try:
        response = waf.get_ip_set(Name=ip_set_name, Scope=scope, Id=ip_set_id)
        addresses = response["IPSet"]["Addresses"]
        lock_token = response["LockToken"]
    except Exception as e:
        logger.error(f"get_ip_set failed: {e}")
        return {"status": "error", "reason": str(e)}

    # 攻撃元IPを抽出
    attacker_ips = extract_attacker_ips(event)
    if not attacker_ips:
        logger.info("No attacker IPs found in the event")
        return {"status": "no_ips_found"}

    logger.info(f"Detected attacker IPs: {attacker_ips}")

    # 新規IPのみ追加
    updated = False
    for ip in attacker_ips:
        cidr = f"{ip}/32"
        if cidr not in addresses:
            addresses.append(cidr)
            updated = True
            logger.info(f"Adding {cidr} to deny-ipset")

    if updated:
        try:
            waf.update_ip_set(
                Name=ip_set_name,
                Scope=scope,
                Id=ip_set_id,
                Addresses=addresses,
                LockToken=lock_token,
            )
            logger.info(f"Successfully blocked IPs: {attacker_ips}")
            return {"status": "updated", "blocked_ips": list(attacker_ips)}
        except Exception as e:
            logger.error(f"update_ip_set failed: {e}")
            return {"status": "error", "reason": str(e)}
    else:
        logger.info("All detected IPs are already in deny-ipset")
        return {"status": "no_update", "already_blocked": list(attacker_ips)}
