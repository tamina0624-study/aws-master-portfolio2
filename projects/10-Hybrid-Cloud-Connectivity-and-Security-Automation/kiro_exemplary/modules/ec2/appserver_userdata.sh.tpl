#!/bin/bash
set -e

# パッケージ更新
yum update -y
yum install -y python3 python3-pip

# Flask + MySQL connector インストール
pip3 install flask mysql-connector-python

# Flaskアプリケーション配置
cat << 'EOF' > /opt/app.py
from flask import Flask, request, jsonify
import mysql.connector
import os

app = Flask(__name__)

def get_db_connection():
    """RDSへの接続を取得"""
    return mysql.connector.connect(
        host="${rds_endpoint}".split(":")[0],
        port=3306,
        user="${rds_user}",
        password="${rds_pass}",
        database="${rds_db}"
    )

@app.route("/")
def index():
    return "<h1>AppServer is running</h1>"

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/db/status")
def db_status():
    """DB接続確認"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()
        return jsonify({"db": "connected"}), 200
    except Exception as e:
        return jsonify({"db": "error", "detail": str(e)}), 500

@app.route("/users", methods=["GET"])
def get_users():
    """ユーザー一覧取得"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, name, email, created_at FROM users")
        result = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
EOF

# systemdサービスとして登録
cat << 'EOF' > /etc/systemd/system/flask-app.service
[Unit]
Description=Flask Application Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app
