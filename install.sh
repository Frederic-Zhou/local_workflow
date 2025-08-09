#!/bin/bash
# install.sh - Ubuntu quick installer for Docker + SSH (root login) + autostart check
set -e

# === 修改这里：root 密码 ===
ROOT_PASSWORD="your_root_password_here"

echo "=== Updating apt ==="
apt-get update -y

echo "=== Installing OpenSSH server + Docker engine ==="
apt-get install -y openssh-server docker.io

# Compose v2 插件（docker compose）
apt-get install -y docker-compose-plugin || true

# 本地 SSH 登录测试需要
apt-get install -y sshpass || true

echo "=== Enable and start services ==="
systemctl enable --now ssh
systemctl enable --now docker

echo "=== Configure SSH for root password login ==="
SSHD_CONFIG="/etc/ssh/sshd_config"
if grep -q "^#\?PermitRootLogin" "$SSHD_CONFIG"; then
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"
else
  echo "PermitRootLogin yes" >> "$SSHD_CONFIG"
fi
if grep -q "^#\?PasswordAuthentication" "$SSHD_CONFIG"; then
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
  echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
fi

echo "=== Setting root password ==="
echo "root:${ROOT_PASSWORD}" | chpasswd
systemctl restart ssh

# ====== 自检 ======
echo
echo "=== Self-check start ==="

# 1) sshd 开机自启
if systemctl is-enabled ssh >/dev/null 2>&1; then
  echo "[OK] SSH service is enabled on boot"
else
  echo "[FAIL] SSH service is NOT enabled on boot"
fi

# 2) docker 开机自启
if systemctl is-enabled docker >/dev/null 2>&1; then
  echo "[OK] Docker service is enabled on boot"
else
  echo "[FAIL] Docker service is NOT enabled on boot"
fi

# 3) docker compose 可用
if docker compose version >/dev/null 2>&1; then
  echo "[OK] Docker Compose v2 is available"
else
  echo "[WARN] Docker Compose v2 NOT found (install docker-compose-plugin)"
fi

# 4) 当前容器（若已起过）restart 策略展示（仅信息）
echo "[INFO] Current containers (if any):"
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

# 5) 本地 root 密码 SSH 测试
if sshpass -p "${ROOT_PASSWORD}" ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@127.0.0.1 "echo [OK] Root SSH login works" 2>/dev/null; then
  echo "[OK] Root SSH login with password is working"
else
  echo "[FAIL] Root SSH login with password FAILED"
fi

echo
echo "=== Versions ==="
docker --version || true
docker compose version || true

echo "=== Done ==="
echo ">>> You can now SSH as root with password from n8n."