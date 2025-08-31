#!/bin/bash

# 服务器环境配置脚本
set -e

echo "🚀 配置服务器环境..."

# 安装Docker
if ! command -v docker &> /dev/null; then
    echo "安装Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# 安装Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "安装Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# 安装Nginx
if ! command -v nginx &> /dev/null; then
    echo "安装Nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

# 创建部署目录
sudo mkdir -p /opt/jobfirst/{staging,production}
sudo chown $USER:$USER /opt/jobfirst/{staging,production}

# 配置Nginx
sudo tee /etc/nginx/sites-available/jobfirst << 'NGINX_CONFIG'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_CONFIG

sudo ln -sf /etc/nginx/sites-available/jobfirst /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "✅ 服务器环境配置完成"
