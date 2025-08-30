# GitHub Secrets 配置指南

## 🔐 概述

本文档提供两种配置GitHub Secrets的方法：
1. **自动化配置** - 使用脚本自动配置
2. **手动配置** - 通过GitHub Web界面手动配置

## 🚀 方法一：自动化配置（推荐）

### 前置要求

1. **安装GitHub CLI**
   ```bash
   # macOS
   brew install gh
   
   # Ubuntu/Debian
   sudo apt install gh
   
   # 其他系统: https://cli.github.com/
   ```

2. **登录GitHub CLI**
   ```bash
   gh auth login
   ```

### 执行配置

1. **运行配置脚本**
   ```bash
   chmod +x scripts/setup-github-secrets.sh
   ./scripts/setup-github-secrets.sh
   ```

2. **按提示输入配置信息**
   - Docker Registry
   - 测试环境配置
   - 生产环境配置
   - 数据库配置
   - 监控配置
   - 通知配置

3. **脚本会自动完成**
   - 生成SSH密钥
   - 配置GitHub Secrets
   - 生成环境文件
   - 提供后续步骤

## 📝 方法二：手动配置

### 1. 访问GitHub Secrets页面

1. 打开您的GitHub仓库
2. 点击 `Settings` 标签
3. 在左侧菜单中点击 `Secrets and variables` → `Actions`
4. 点击 `New repository secret` 按钮

### 2. 配置必要的Secrets

#### 基础配置
```bash
# Docker Registry
DOCKER_REGISTRY = ghcr.io
```

#### 测试环境配置
```bash
# 测试环境主机地址
STAGING_HOST = your-staging-server.com

# 测试环境用户名
STAGING_USER = ubuntu

# 测试环境部署路径
STAGING_PATH = /opt/jobfirst/staging
```

#### 生产环境配置
```bash
# 生产环境主机地址
PROD_HOST = your-prod-server.com

# 生产环境用户名
PROD_USER = ubuntu

# 生产环境部署路径
PROD_PATH = /opt/jobfirst/production
```

#### 数据库配置
```bash
# MySQL Root密码
MYSQL_ROOT_PASSWORD = your-mysql-root-password

# MySQL用户密码
MYSQL_PASSWORD = your-mysql-password

# MySQL数据库名
MYSQL_DATABASE = jobfirst
```

#### 监控配置
```bash
# Grafana管理员密码
GRAFANA_PASSWORD = your-grafana-password

# Neo4j认证信息
NEO4J_AUTH = neo4j/your-neo4j-password
```

#### 通知配置（可选）
```bash
# Slack Webhook URL
SLACK_WEBHOOK = https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

#### SSH密钥配置

1. **生成SSH密钥**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "jobfirst-ci-cd"
   ```

2. **配置私钥**
   ```bash
   # 复制私钥内容
   cat ~/.ssh/id_rsa
   
   # 在GitHub中创建secret
   STAGING_SSH_PRIVATE_KEY = [粘贴私钥内容]
   PROD_SSH_PRIVATE_KEY = [粘贴私钥内容]
   ```

3. **配置公钥到服务器**
   ```bash
   # 复制公钥到测试环境
   ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@your-staging-server.com
   
   # 复制公钥到生产环境
   ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@your-prod-server.com
   ```

## 🔧 服务器环境准备

### 1. 安装必要软件

```bash
# 连接到服务器
ssh ubuntu@your-server.com

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装Nginx
sudo apt update
sudo apt install -y nginx
```

### 2. 创建部署目录

```bash
# 创建目录
sudo mkdir -p /opt/jobfirst/{staging,production}
sudo chown $USER:$USER /opt/jobfirst/{staging,production}
```

### 3. 配置Nginx

```bash
# 创建Nginx配置
sudo tee /etc/nginx/sites-available/jobfirst << 'EOF'
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
EOF

# 启用配置
sudo ln -sf /etc/nginx/sites-available/jobfirst /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## ✅ 验证配置

### 1. 检查GitHub Secrets

在GitHub仓库的 `Settings` → `Secrets and variables` → `Actions` 页面中，确认以下Secrets已配置：

- ✅ `DOCKER_REGISTRY`
- ✅ `STAGING_HOST`
- ✅ `STAGING_USER`
- ✅ `STAGING_PATH`
- ✅ `PROD_HOST`
- ✅ `PROD_USER`
- ✅ `PROD_PATH`
- ✅ `MYSQL_ROOT_PASSWORD`
- ✅ `MYSQL_PASSWORD`
- ✅ `MYSQL_DATABASE`
- ✅ `GRAFANA_PASSWORD`
- ✅ `NEO4J_AUTH`
- ✅ `STAGING_SSH_PRIVATE_KEY`
- ✅ `PROD_SSH_PRIVATE_KEY`
- ✅ `SLACK_WEBHOOK` (可选)

### 2. 测试SSH连接

```bash
# 测试测试环境连接
ssh ubuntu@your-staging-server.com "echo 'SSH连接成功'"

# 测试生产环境连接
ssh ubuntu@your-prod-server.com "echo 'SSH连接成功'"
```

### 3. 测试CI/CD流程

```bash
# 推送到develop分支测试
git push origin develop

# 推送到main分支部署生产
git push origin main
```

## 🚨 安全注意事项

### 1. 密钥管理
- 使用强密码
- 定期轮换密钥
- 不要在代码中硬编码密钥

### 2. 访问控制
- 限制服务器访问权限
- 使用SSH密钥而非密码
- 定期审查访问权限

### 3. 监控告警
- 配置异常访问告警
- 监控部署日志
- 定期安全审计

## 🔄 更新配置

### 更新单个Secret
```bash
# 使用GitHub CLI
gh secret set SECRET_NAME --body "new-value" --repo "your-username/your-repo"

# 或通过Web界面
# Settings → Secrets and variables → Actions → 编辑对应secret
```

### 批量更新
```bash
# 运行配置脚本重新配置
./scripts/setup-github-secrets.sh
```

## 📞 故障排除

### 常见问题

1. **SSH连接失败**
   ```bash
   # 检查SSH密钥
   ssh-keygen -l -f ~/.ssh/id_rsa.pub
   
   # 重新配置SSH密钥
   ssh-copy-id -i ~/.ssh/id_rsa.pub user@server
   ```

2. **Docker权限问题**
   ```bash
   # 添加用户到docker组
   sudo usermod -aG docker $USER
   
   # 重新登录或重启
   newgrp docker
   ```

3. **Nginx配置错误**
   ```bash
   # 检查配置语法
   sudo nginx -t
   
   # 查看错误日志
   sudo tail -f /var/log/nginx/error.log
   ```

### 获取帮助

- GitHub Actions文档: https://docs.github.com/en/actions
- GitHub CLI文档: https://cli.github.com/
- Docker文档: https://docs.docker.com/

---

配置完成后，您的CI/CD流水线就可以自动运行了！🎉
