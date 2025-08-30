#!/bin/bash

# GitHub Secrets 配置脚本
set -e

echo "🔐 开始配置 GitHub Secrets..."

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_blue() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# 检查必要的工具
check_requirements() {
    log_info "检查必要工具..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) 未安装"
        log_info "请先安装 GitHub CLI: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI 未登录"
        log_info "请先登录: gh auth login"
        exit 1
    fi
    
    log_info "工具检查通过"
}

# 获取仓库信息
get_repo_info() {
    log_info "获取仓库信息..."
    
    # 获取当前仓库
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    if [ -z "$REPO" ]; then
        log_error "无法获取仓库信息，请确保在正确的Git仓库中"
        exit 1
    fi
    
    log_info "当前仓库: $REPO"
}

# 交互式配置
interactive_setup() {
    log_blue "开始交互式配置 GitHub Secrets..."
    
    echo ""
    log_info "请输入以下配置信息："
    echo ""
    
    # 容器仓库配置
    read -p "Docker Registry (默认: ghcr.io): " DOCKER_REGISTRY
    DOCKER_REGISTRY=${DOCKER_REGISTRY:-ghcr.io}
    
    # 测试环境配置
    echo ""
    log_info "测试环境配置:"
    read -p "测试环境主机地址: " STAGING_HOST
    read -p "测试环境用户名 (默认: ubuntu): " STAGING_USER
    STAGING_USER=${STAGING_USER:-ubuntu}
    read -p "测试环境部署路径 (默认: /opt/jobfirst/staging): " STAGING_PATH
    STAGING_PATH=${STAGING_PATH:-/opt/jobfirst/staging}
    
    # 生产环境配置
    echo ""
    log_info "生产环境配置:"
    read -p "生产环境主机地址: " PROD_HOST
    read -p "生产环境用户名 (默认: ubuntu): " PROD_USER
    PROD_USER=${PROD_USER:-ubuntu}
    read -p "生产环境部署路径 (默认: /opt/jobfirst/production): " PROD_PATH
    PROD_PATH=${PROD_PATH:-/opt/jobfirst/production}
    
    # 数据库配置
    echo ""
    log_info "数据库配置:"
    read -s -p "MySQL Root密码: " MYSQL_ROOT_PASSWORD
    echo ""
    read -s -p "MySQL用户密码: " MYSQL_PASSWORD
    echo ""
    read -p "MySQL数据库名 (默认: jobfirst): " MYSQL_DATABASE
    MYSQL_DATABASE=${MYSQL_DATABASE:-jobfirst}
    
    # 监控配置
    echo ""
    log_info "监控配置:"
    read -s -p "Grafana管理员密码: " GRAFANA_PASSWORD
    echo ""
    read -s -p "Neo4j密码: " NEO4J_PASSWORD
    echo ""
    
    # 通知配置
    echo ""
    log_info "通知配置:"
    read -p "Slack Webhook URL (可选): " SLACK_WEBHOOK
    
    # 确认配置
    echo ""
    log_blue "配置确认:"
    echo "Docker Registry: $DOCKER_REGISTRY"
    echo "测试环境: $STAGING_USER@$STAGING_HOST:$STAGING_PATH"
    echo "生产环境: $PROD_USER@$PROD_HOST:$PROD_PATH"
    echo "MySQL数据库: $MYSQL_DATABASE"
    echo ""
    
    read -p "确认以上配置? (y/N): " CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        log_warn "配置已取消"
        exit 0
    fi
}

# 生成SSH密钥
generate_ssh_keys() {
    log_info "生成SSH密钥..."
    
    # 检查是否已有SSH密钥
    if [ -f ~/.ssh/id_rsa ]; then
        log_warn "SSH密钥已存在，跳过生成"
        return
    fi
    
    # 生成SSH密钥
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "jobfirst-ci-cd"
    
    log_info "SSH密钥生成完成"
}

# 配置Secrets
configure_secrets() {
    log_info "配置 GitHub Secrets..."
    
    # 基础配置
    gh secret set DOCKER_REGISTRY --body "$DOCKER_REGISTRY" --repo "$REPO"
    log_info "✓ DOCKER_REGISTRY 已设置"
    
    # 测试环境配置
    gh secret set STAGING_HOST --body "$STAGING_HOST" --repo "$REPO"
    gh secret set STAGING_USER --body "$STAGING_USER" --repo "$REPO"
    gh secret set STAGING_PATH --body "$STAGING_PATH" --repo "$REPO"
    log_info "✓ 测试环境配置已设置"
    
    # 生产环境配置
    gh secret set PROD_HOST --body "$PROD_HOST" --repo "$REPO"
    gh secret set PROD_USER --body "$PROD_USER" --repo "$REPO"
    gh secret set PROD_PATH --body "$PROD_PATH" --repo "$REPO"
    log_info "✓ 生产环境配置已设置"
    
    # 数据库配置
    gh secret set MYSQL_ROOT_PASSWORD --body "$MYSQL_ROOT_PASSWORD" --repo "$REPO"
    gh secret set MYSQL_PASSWORD --body "$MYSQL_PASSWORD" --repo "$REPO"
    gh secret set MYSQL_DATABASE --body "$MYSQL_DATABASE" --repo "$REPO"
    log_info "✓ 数据库配置已设置"
    
    # 监控配置
    gh secret set GRAFANA_PASSWORD --body "$GRAFANA_PASSWORD" --repo "$REPO"
    gh secret set NEO4J_AUTH --body "neo4j/$NEO4J_PASSWORD" --repo "$REPO"
    log_info "✓ 监控配置已设置"
    
    # 通知配置
    if [ -n "$SLACK_WEBHOOK" ]; then
        gh secret set SLACK_WEBHOOK --body "$SLACK_WEBHOOK" --repo "$REPO"
        log_info "✓ Slack通知配置已设置"
    fi
    
    # SSH密钥配置
    STAGING_SSH_KEY=$(cat ~/.ssh/id_rsa)
    PROD_SSH_KEY=$(cat ~/.ssh/id_rsa)
    
    gh secret set STAGING_SSH_PRIVATE_KEY --body "$STAGING_SSH_KEY" --repo "$REPO"
    gh secret set PROD_SSH_PRIVATE_KEY --body "$PROD_SSH_KEY" --repo "$REPO"
    log_info "✓ SSH密钥配置已设置"
}

# 验证配置
verify_secrets() {
    log_info "验证 Secrets 配置..."
    
    # 获取所有secrets
    SECRETS=$(gh secret list --repo "$REPO" --json name)
    
    # 检查必要的secrets
    REQUIRED_SECRETS=(
        "DOCKER_REGISTRY"
        "STAGING_HOST"
        "STAGING_USER"
        "STAGING_PATH"
        "PROD_HOST"
        "PROD_USER"
        "PROD_PATH"
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_PASSWORD"
        "MYSQL_DATABASE"
        "GRAFANA_PASSWORD"
        "NEO4J_AUTH"
        "STAGING_SSH_PRIVATE_KEY"
        "PROD_SSH_PRIVATE_KEY"
    )
    
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if echo "$SECRETS" | grep -q "$secret"; then
            log_info "✓ $secret 已配置"
        else
            log_warn "⚠ $secret 未配置"
        fi
    done
}

# 生成环境文件
generate_env_files() {
    log_info "生成环境配置文件..."
    
    # 生成 .env.example
    cat > .env.example << EOF
# Docker Registry
DOCKER_REGISTRY=$DOCKER_REGISTRY

# Staging Environment
STAGING_HOST=$STAGING_HOST
STAGING_USER=$STAGING_USER
STAGING_PATH=$STAGING_PATH

# Production Environment
PROD_HOST=$PROD_HOST
PROD_USER=$PROD_USER
PROD_PATH=$PROD_PATH

# Database Configuration
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_USER=jobfirst
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_DATABASE=$MYSQL_DATABASE

# Monitoring Configuration
GRAFANA_PASSWORD=$GRAFANA_PASSWORD
NEO4J_AUTH=neo4j/$NEO4J_PASSWORD

# Notification Configuration
SLACK_WEBHOOK=$SLACK_WEBHOOK
EOF
    
    log_info "✓ .env.example 已生成"
    
    # 生成服务器配置脚本
    cat > scripts/setup-server-env.sh << 'EOF'
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
EOF
    
    chmod +x scripts/setup-server-env.sh
    log_info "✓ 服务器配置脚本已生成"
}

# 显示后续步骤
show_next_steps() {
    log_blue "🎉 GitHub Secrets 配置完成！"
    echo ""
    log_info "后续步骤："
    echo ""
    echo "1. 配置服务器环境："
    echo "   scp scripts/setup-server-env.sh $STAGING_USER@$STAGING_HOST:~/"
    echo "   ssh $STAGING_USER@$STAGING_HOST 'chmod +x setup-server-env.sh && ./setup-server-env.sh'"
    echo ""
    echo "2. 配置SSH密钥到服务器："
    echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub $STAGING_USER@$STAGING_HOST"
    echo "   ssh-copy-id -i ~/.ssh/id_rsa.pub $PROD_USER@$PROD_HOST"
    echo ""
    echo "3. 测试CI/CD流程："
    echo "   git push origin develop  # 测试环境部署"
    echo "   git push origin main     # 生产环境部署"
    echo ""
    echo "4. 查看部署状态："
    echo "   https://github.com/$REPO/actions"
    echo ""
}

# 主函数
main() {
    log_blue "开始配置 GitHub Secrets..."
    
    check_requirements
    get_repo_info
    interactive_setup
    generate_ssh_keys
    configure_secrets
    verify_secrets
    generate_env_files
    show_next_steps
}

# 执行主函数
main "$@"
