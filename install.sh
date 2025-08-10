#!/bin/bash
# install.sh - Ubuntu quick installer for Docker + SSH + autostart check
set -e

echo "=== Updating apt ==="
apt-get update -y

echo "=== Installing OpenSSH server + Docker engine ==="
apt-get install -y openssh-server docker.io

# 安装 docker compose v2 插件（可选，但推荐）
apt-get install -y docker-compose-plugin || true

# 安装 sshpass（可选，用于脚本测试 SSH）
apt-get install -y sshpass || true

echo "=== Enable and start services ==="
systemctl enable --now ssh
systemctl enable --now docker

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

echo
echo "=== Versions ==="
docker --version || true
docker compose version || true

echo "=== Done ==="