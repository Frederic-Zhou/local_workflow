

# 1) 安装 & 配置（Ubuntu 上）
sudo chmod +x install.sh
sudo ./install.sh

# 2) 启动容器
docker compose up -d

# 3) n8n 里用 SSH 节点（root+密码）执行：
#    docker exec appium adb devices -l
#    然后解析 usb:… → serial，用 serial 调 Appium API（http://appium:4723）