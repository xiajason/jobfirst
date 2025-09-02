#!/bin/bash

# JobFirst 本地测试环境启动脚本
# 用于在本地Docker环境中启动完整的微服务架构

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

# 检查Docker是否运行
check_docker() {
    log_info "检查Docker服务状态..."
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker服务未运行，请启动Docker Desktop"
        exit 1
    fi
    log_success "Docker服务运行正常"
}

# 检查Docker Compose
check_docker_compose() {
    log_info "检查Docker Compose..."
    if ! docker-compose --version > /dev/null 2>&1; then
        log_error "Docker Compose未安装或不可用"
        exit 1
    fi
    log_success "Docker Compose可用"
}

# 检查必要的文件
check_files() {
    log_info "检查必要文件..."
    
    local required_files=(
        "docker-compose.local-test.yml"
        "backend/ai-service/Dockerfile"
        "backend/gateway/Dockerfile"
        "backend/user/Dockerfile"
        "backend/resume/Dockerfile"
        "frontend/web/Dockerfile"
        "init.sql"
        "monitoring/prometheus.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "缺少必要文件: $file"
            exit 1
        fi
    done
    
    log_success "所有必要文件检查通过"
}

# 清理现有环境
cleanup_environment() {
    log_info "清理现有环境..."
    
    # 停止并删除现有容器
    if docker-compose -f docker-compose.local-test.yml ps -q | grep -q .; then
        log_info "停止现有服务..."
        docker-compose -f docker-compose.local-test.yml down --volumes --remove-orphans
    fi
    
    # 清理未使用的Docker资源
    log_info "清理Docker资源..."
    docker system prune -f
    
    log_success "环境清理完成"
}

# 启动服务
start_services() {
    log_info "启动本地测试环境..."
    
    # 启动所有服务
    docker-compose -f docker-compose.local-test.yml up -d
    
    log_success "服务启动命令已执行"
}

# 等待服务启动
wait_for_services() {
    log_info "等待服务启动..."
    
    local max_attempts=60
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "等待服务启动... ($attempt/$max_attempts)"
        
        # 检查数据库服务
        if docker-compose -f docker-compose.local-test.yml exec -T postgres pg_isready -U jobfirst_user -d jobfirst > /dev/null 2>&1; then
            log_success "PostgreSQL服务已就绪"
            break
        fi
        
        sleep 5
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        log_error "服务启动超时"
        exit 1
    fi
    
    # 等待其他服务启动
    log_info "等待其他服务启动..."
    sleep 30
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    local services=(
        "gateway:8080"
        "ai-service:8000"
        "user-service:8081"
        "resume-service:8082"
        "web-frontend:3000"
    )
    
    local all_healthy=true
    
    for service in "${services[@]}"; do
        local name=$(echo $service | cut -d: -f1)
        local port=$(echo $service | cut -d: -f2)
        
        log_info "检查 $name 服务 (端口: $port)..."
        
        if curl -f "http://localhost:$port/health" > /dev/null 2>&1 || \
           curl -f "http://localhost:$port/api/v1/health" > /dev/null 2>&1 || \
           curl -f "http://localhost:$port" > /dev/null 2>&1; then
            log_success "$name 服务健康检查通过"
        else
            log_warning "$name 服务健康检查失败"
            all_healthy=false
        fi
    done
    
    if [[ "$all_healthy" == true ]]; then
        log_success "所有服务健康检查通过"
    else
        log_warning "部分服务健康检查失败，请检查日志"
    fi
}

# 显示服务状态
show_status() {
    log_info "显示服务状态..."
    docker-compose -f docker-compose.local-test.yml ps
    
    echo ""
    log_success "=== 本地测试环境部署完成 ==="
    echo "服务访问地址："
    echo "- 网关服务: http://localhost:8080"
    echo "- AI服务: http://localhost:8000"
    echo "- 用户服务: http://localhost:8081"
    echo "- 简历服务: http://localhost:8082"
    echo "- Web前端: http://localhost:3000"
    echo "- Prometheus: http://localhost:9090"
    echo "- Grafana: http://localhost:3001 (admin/admin)"
    echo ""
    echo "管理命令："
    echo "- 查看状态: docker-compose -f docker-compose.local-test.yml ps"
    echo "- 查看日志: docker-compose -f docker-compose.local-test.yml logs -f"
    echo "- 停止服务: docker-compose -f docker-compose.local-test.yml down"
    echo "- 重启服务: docker-compose -f docker-compose.local-test.yml restart"
    echo ""
    echo "数据库连接信息："
    echo "- PostgreSQL: localhost:5432 (jobfirst/jobfirst_user/jobfirst_pass)"
    echo "- Redis: localhost:6379"
}

# 主函数
main() {
    echo "🚀 JobFirst 本地测试环境启动脚本"
    echo "=================================="
    
    check_docker
    check_docker_compose
    check_files
    cleanup_environment
    start_services
    wait_for_services
    health_check
    show_status
    
    log_success "本地测试环境启动完成！"
}

# 错误处理
trap 'log_error "脚本执行失败，退出码: $?"' ERR

# 执行主函数
main "$@"
