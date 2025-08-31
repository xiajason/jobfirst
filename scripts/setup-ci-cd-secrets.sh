#!/bin/bash

# JobFirst CI/CD Secrets 配置脚本
# 用于快速配置GitHub Actions所需的Secrets

set -e

echo "🚀 JobFirst CI/CD Secrets 配置脚本"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}📋 检查依赖...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ GitHub CLI (gh) 未安装${NC}"
        echo "请先安装 GitHub CLI: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ 未登录 GitHub CLI${NC}"
        echo "请先运行: gh auth login"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 依赖检查通过${NC}"
}

# 获取用户输入
get_user_input() {
    echo -e "${BLUE}📝 请输入配置信息:${NC}"
    
    read -p "Docker Hub 用户名: " DOCKER_USERNAME
    read -s -p "Docker Hub 密码/访问令牌: " DOCKER_PASSWORD
    echo
    
    read -p "腾讯云测试环境服务器IP: " TENCENT_STAGING_HOST
    read -p "SSH用户名 (通常是 ubuntu): " TENCENT_USER
    
    echo -e "${YELLOW}SSH私钥文件路径 (例如: ~/.ssh/id_rsa):${NC}"
    read -p "SSH私钥文件路径: " SSH_KEY_PATH
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}❌ SSH私钥文件不存在: $SSH_KEY_PATH${NC}"
        exit 1
    fi
}

# 读取SSH私钥
read_ssh_key() {
    echo -e "${BLUE}🔑 读取SSH私钥...${NC}"
    TENCENT_SSH_KEY=$(cat "$SSH_KEY_PATH")
    echo -e "${GREEN}✅ SSH私钥读取成功${NC}"
}

# 配置GitHub Secrets
configure_github_secrets() {
    echo -e "${BLUE}🔧 配置GitHub Secrets...${NC}"
    
    # 设置仓库
    REPO="xiajason/jobfirst"
    
    # 配置Docker Hub Secrets
    echo -e "${YELLOW}配置Docker Hub Secrets...${NC}"
    gh secret set DOCKER_USERNAME --repo "$REPO" --body "$DOCKER_USERNAME"
    gh secret set DOCKER_PASSWORD --repo "$REPO" --body "$DOCKER_PASSWORD"
    
    # 配置腾讯云Secrets
    echo -e "${YELLOW}配置腾讯云Secrets...${NC}"
    gh secret set TENCENT_STAGING_HOST --repo "$REPO" --body "$TENCENT_STAGING_HOST"
    gh secret set TENCENT_USER --repo "$REPO" --body "$TENCENT_USER"
    gh secret set TENCENT_SSH_KEY --repo "$REPO" --body "$TENCENT_SSH_KEY"
    
    echo -e "${GREEN}✅ GitHub Secrets 配置完成${NC}"
}

# 验证配置
verify_configuration() {
    echo -e "${BLUE}🔍 验证配置...${NC}"
    
    # 检查Secrets是否设置成功
    echo -e "${YELLOW}检查GitHub Secrets...${NC}"
    gh secret list --repo "xiajason/jobfirst"
    
    echo -e "${GREEN}✅ 配置验证完成${NC}"
}

# 显示下一步操作
show_next_steps() {
    echo -e "${GREEN}🎉 配置完成！${NC}"
    echo "=================================="
    echo -e "${BLUE}📋 下一步操作:${NC}"
    echo "1. 推送代码到develop分支触发测试环境部署:"
    echo "   git checkout develop"
    echo "   git add ."
    echo "   git commit -m 'test: 触发测试环境自动部署'"
    echo "   git push origin develop"
    echo ""
    echo "2. 查看部署状态:"
    echo "   gh run list --repo xiajason/jobfirst"
    echo ""
    echo "3. 访问测试环境:"
    echo "   - API网关: http://$TENCENT_STAGING_HOST:8000"
    echo "   - 共享基础设施: http://$TENCENT_STAGING_HOST:8210"
    echo "   - Grafana监控: http://$TENCENT_STAGING_HOST:3001"
    echo ""
    echo -e "${YELLOW}📖 详细配置指南: docs/TEST_ENVIRONMENT_CI_CD_SETUP.md${NC}"
}

# 主函数
main() {
    check_dependencies
    get_user_input
    read_ssh_key
    configure_github_secrets
    verify_configuration
    show_next_steps
}

# 运行主函数
main "$@"
