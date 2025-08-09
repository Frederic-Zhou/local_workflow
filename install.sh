#!/bin/bash
# install.sh - Ubuntu quick installer for Docker + SSH (root login) + autostart check
set -e

# ==== 配置 ====
ROOT_PASSWORD="your_root_password_here"   # ⚠️ 修改成你想用的 root 密码

echo "=== Updating apt ==="
apt-get update -y

echo "=== Installing OpenSSH server + Docker engine (docker.io) ==="
apt-get install -y openssh-server docker.io

# 可选：安装 compose V2 插件（建议）
apt-get install -y docker-compose-plugin || true

echo "=== Configure SSH for root password login ==="
# 允许 root 密码登录
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 设置 root 密码
echo "root:${ROOT_PASSWORD}" | chpasswd

echo "=== Enable and start services ==="
systemctl enable --now ssh
systemctl enable --now docker

# 重启 sshd 让配置生效
systemctl restart ssh

# ==== 检查部分 ====
echo
echo "=== Self-check start ==="

# 1. 检查 sshd 是否开机自启
if systemctl is-enabled ssh >/dev/null; then
  echo "[OK] SSH service is enabled on boot"
else
  echo "[FAIL] SSH service is NOT enabled on boot"
fi

# 2. 检查 docker 是否开机自启
if systemctl is-enabled docker >/dev/null; then
  echo "[OK] Docker service is enabled on boot"
else
  echo "[FAIL] Docker service is NOT enabled on boot"
fi

# 3. 检查 docker compose 是否可用
if docker compose version >/dev/null 2>&1; then
  echo "[OK] Docker Compose v2 is available"
else
  echo "[WARN] Docker Compose v2 NOT found"
fi

# 4. 检查 restart 策略
echo "[INFO] Checking restart policies..."
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}\t{{.Label "com.docker.compose.project"}}' || true

# 5. 测试 root 密码是否可用（本地 127.0.0.1）
if sshpass -p "${ROOT_PASSWORD}" ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@127.0.0.1 "echo [OK] Root SSH login works" 2>/dev/null; then
  echo "[OK] Root SSH login with password is working"
else
  echo "[FAIL] Root SSH login with password FAILED"
fi

echo "=== Install + Check complete ==="
echo ">>> Reboot machine to confirm auto-start behavior <<<"