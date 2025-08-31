# 🚀 生产环境快速配置指南

## 📋 概述

本文档提供生产环境的快速配置方案，让您可以立即开始生产环境部署。

## 🎯 快速配置方案

### 方案一：使用现有服务器（推荐）

如果您有可用的服务器，可以快速配置：

#### 1. 服务器要求
- **操作系统**: Ubuntu 20.04+ / CentOS 7+
- **内存**: 最少 4GB，推荐 8GB+
- **存储**: 最少 50GB，推荐 100GB+
- **网络**: 公网IP，开放80/443端口

#### 2. 快速配置命令
```bash
# 连接到您的服务器
ssh root@your-production-server.com

# 创建部署用户
adduser ubuntu
usermod -aG sudo ubuntu

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# 安装Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 安装Nginx
apt update && apt install -y nginx

# 创建部署目录
mkdir -p /opt/jobfirst/production
chown ubuntu:ubuntu /opt/jobfirst/production
```

#### 3. 配置SSH密钥
```bash
# 在本地执行
ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@your-production-server.com
```

#### 4. 更新GitHub Secrets
```bash
# 更新生产环境配置
gh secret set PROD_HOST --body "your-production-server.com" --repo "xiajason/jobfirst"
```

### 方案二：云服务商快速部署

#### 腾讯云（推荐）
1. **购买云服务器**
   - 地域：选择离用户最近的地区
   - 配置：4核8GB，100GB SSD
   - 系统：Ubuntu 22.04 LTS

2. **安全组配置**
   - 开放端口：22(SSH), 80(HTTP), 443(HTTPS)
   - 限制访问IP（可选）

3. **域名配置**
   - 购买域名（可选）
   - 配置DNS解析

#### 阿里云
1. **购买ECS实例**
   - 配置：4核8GB，100GB ESSD
   - 系统：Ubuntu 22.04 LTS

2. **安全组配置**
   - 开放必要端口

#### AWS
1. **启动EC2实例**
   - 实例类型：t3.medium或更高
   - AMI：Ubuntu 22.04 LTS

2. **安全组配置**
   - 开放必要端口

## 🔧 生产环境配置

### 1. 环境变量配置
```bash
# 生产环境专用配置
export NODE_ENV=production
export DB_HOST=localhost
export DB_PORT=3306
export REDIS_HOST=localhost
export REDIS_PORT=6379
```

### 2. 数据库配置
```bash
# 创建生产数据库
mysql -u root -p
CREATE DATABASE jobfirst_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'jobfirst_prod'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON jobfirst_prod.* TO 'jobfirst_prod'@'localhost';
FLUSH PRIVILEGES;
```

### 3. SSL证书配置
```bash
# 安装Certbot
apt install -y certbot python3-certbot-nginx

# 获取SSL证书
certbot --nginx -d your-domain.com
```

## 🚀 快速部署

### 1. 推送代码到main分支
```bash
# 合并develop到main
git checkout main
git merge develop
git push origin main
```

### 2. 监控部署状态
```bash
# 查看GitHub Actions状态
gh run list --limit 5

# 查看部署日志
gh run view <run-id> --log
```

### 3. 验证部署
```bash
# 检查服务状态
curl -f http://your-production-server.com/health

# 检查API接口
curl -f http://your-production-server.com/api/v2/jobs/
```

## 📊 监控和告警

### 1. 基础监控
```bash
# 系统监控
htop
df -h
free -h

# 服务监控
docker ps
docker stats
```

### 2. 日志监控
```bash
# 查看应用日志
docker logs jobfirst-gateway
docker logs jobfirst-user

# 查看系统日志
journalctl -u docker
journalctl -u nginx
```

### 3. 告警配置
- 配置邮件告警
- 配置Slack通知
- 配置短信告警（可选）

## 🔒 安全配置

### 1. 防火墙配置
```bash
# 配置UFW防火墙
ufw allow ssh
ufw allow 'Nginx Full'
ufw enable
```

### 2. 定期备份
```bash
# 数据库备份脚本
#!/bin/bash
mysqldump -u root -p jobfirst_prod > /backup/jobfirst_$(date +%Y%m%d_%H%M%S).sql
```

### 3. 安全更新
```bash
# 定期更新系统
apt update && apt upgrade -y
```

## 📈 性能优化

### 1. 数据库优化
```sql
-- 优化MySQL配置
SET GLOBAL innodb_buffer_pool_size = 1073741824; -- 1GB
SET GLOBAL max_connections = 200;
```

### 2. 应用优化
```yaml
# docker-compose.prod.yml 优化
services:
  gateway:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### 3. Nginx优化
```nginx
# nginx.conf 优化
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
```

## 🎯 下一步行动

### 立即行动（今天）
1. **选择服务器方案**
2. **配置基础环境**
3. **更新GitHub Secrets**
4. **测试部署流程**

### 短期目标（本周）
1. **完成生产环境部署**
2. **配置监控告警**
3. **进行安全加固**
4. **性能测试和优化**

### 中期目标（本月）
1. **完善监控体系**
2. **建立备份策略**
3. **制定运维流程**
4. **团队培训**

## 📞 支持

### 紧急联系
- **技术问题**: 开发团队
- **部署问题**: DevOps团队
- **服务器问题**: 云服务商支持

### 文档资源
- [GitHub Actions文档](https://docs.github.com/en/actions)
- [Docker文档](https://docs.docker.com/)
- [Nginx文档](https://nginx.org/en/docs/)

---

**配置完成后，您就可以放心进行二次开发了！** 🎉

