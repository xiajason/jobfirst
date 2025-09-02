#!/bin/bash

# JobFirst 本地测试环境停止脚本
# 用于优雅地停止和清理本地测试环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker Compose文件
check_compose_file() {
    if [[ ! -f "docker-compose.local-test.yml" ]]; then
        log_error "找不到 docker-compose.local-test.yml 文件"
        exit 1
    fi
}

# 停止服务
stop_services() {
    log_info "停止本地测试环境服务..."
    
    if docker-compose -f docker-compose.local-test.yml ps -q | grep -q .; then
        log_info "正在停止服务..."
        docker-compose -f docker-compose.local-test.yml down --volumes --remove-orphans
        log_success "服务已停止"
    else
        log_info "没有运行中的服务"
    fi
}

# 清理资源
cleanup_resources() {
    log_info "清理Docker资源..."
    
    # 清理未使用的容器、网络、镜像
    docker system prune -f
    
    # 清理未使用的卷（可选）
    read -p "是否清理未使用的卷？这可能会删除数据 (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warning "清理未使用的卷..."
        docker volume prune -f
        log_success "卷清理完成"
    else
        log_info "跳过卷清理"
    fi
}

# 显示清理结果
show_cleanup_result() {
    log_success "=== 本地测试环境清理完成 ==="
    echo ""
    echo "清理结果："
    echo "- 所有服务已停止"
    echo "- 容器已删除"
    echo "- 网络已清理"
    echo "- 未使用的资源已清理"
    echo ""
    echo "如需重新启动，请运行："
    echo "  ./scripts/start-local-test.sh"
    echo ""
    echo "或手动启动："
    echo "  docker-compose -f docker-compose.local-test.yml up -d"
}

# 主函数
main() {
    echo "🛑 JobFirst 本地测试环境停止脚本"
    echo "=================================="
    
    check_compose_file
    stop_services
    cleanup_resources
    show_cleanup_result
    
    log_success "本地测试环境清理完成！"
}

# 错误处理
trap 'log_error "脚本执行失败，退出码: $?"' ERR

# 执行主函数
main "$@"
