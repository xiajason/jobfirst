#!/bin/bash

# JobFirst 集成部署脚本
# 包含共享基础设施、API网关、监控服务等

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
    log_info "检查Docker状态..."
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker未运行，请启动Docker"
        exit 1
    fi
    log_success "Docker运行正常"
}

# 检查Docker Compose是否可用
check_docker_compose() {
    log_info "检查Docker Compose..."
    if ! docker-compose --version > /dev/null 2>&1; then
        log_error "Docker Compose不可用"
        exit 1
    fi
    log_success "Docker Compose可用"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    mkdir -p logs
    mkdir -p monitoring/grafana/dashboards
    mkdir -p monitoring/grafana/datasources
    log_success "目录创建完成"
}

# 停止现有服务
stop_existing_services() {
    log_info "停止现有服务..."
    if docker-compose -f docker-compose.yml ps -q | grep -q .; then
        docker-compose -f docker-compose.yml down
        log_success "现有服务已停止"
    else
        log_info "没有运行的服务"
    fi
}

# 构建镜像
build_images() {
    log_info "构建Docker镜像..."
    
    # 构建共享基础设施镜像
    log_info "构建共享基础设施镜像..."
    docker build -t jobfirst/shared-infrastructure:latest ./backend/shared/infrastructure
    
    # 构建API网关镜像
    log_info "构建API网关镜像..."
    docker build -t jobfirst/gateway:latest ./backend/gateway
    
    # 构建业务服务镜像
    log_info "构建业务服务镜像..."
    docker build -t jobfirst/user-service:latest ./backend/user
    docker build -t jobfirst/resume-service:latest ./backend/resume
    docker build -t jobfirst/ai-service:latest ./backend/ai-service
    
    log_success "所有镜像构建完成"
}

# 启动基础设施服务
start_infrastructure() {
    log_info "启动基础设施服务..."
    docker-compose -f docker-compose.integrated.yml up -d mysql redis consul neo4j postgresql
    
    # 等待服务启动
    log_info "等待基础设施服务启动..."
    sleep 30
    
    # 检查服务健康状态
    check_service_health "mysql" "http://localhost:8200"
    check_service_health "redis" "redis://localhost:8201"
    check_service_health "consul" "http://localhost:8202/v1/status/leader"
    
    log_success "基础设施服务启动完成"
}

# 启动共享基础设施
start_shared_infrastructure() {
    log_info "启动共享基础设施服务..."
    docker-compose -f docker-compose.integrated.yml up -d shared-infrastructure
    
    # 等待服务启动
    log_info "等待共享基础设施服务启动..."
    sleep 20
    
    # 检查服务健康状态
    check_service_health "shared-infrastructure" "http://localhost:8210/health"
    
    log_success "共享基础设施服务启动完成"
}

# 启动API网关
start_gateway() {
    log_info "启动API网关..."
    docker-compose -f docker-compose.integrated.yml up -d gateway
    
    # 等待服务启动
    log_info "等待API网关启动..."
    sleep 15
    
    # 检查服务健康状态
    check_service_health "gateway" "http://localhost:8000/health"
    
    log_success "API网关启动完成"
}

# 启动业务服务
start_business_services() {
    log_info "启动业务服务..."
    docker-compose -f docker-compose.integrated.yml up -d user resume ai
    
    # 等待服务启动
    log_info "等待业务服务启动..."
    sleep 20
    
    # 检查服务健康状态
    check_service_health "user-service" "http://localhost:8001/health"
    check_service_health "resume-service" "http://localhost:8002/health"
    check_service_health "ai-service" "http://localhost:8206/health"
    
    log_success "业务服务启动完成"
}

# 启动监控服务
start_monitoring() {
    log_info "启动监控服务..."
    docker-compose -f docker-compose.integrated.yml up -d prometheus grafana
    
    # 等待服务启动
    log_info "等待监控服务启动..."
    sleep 20
    
    # 检查服务健康状态
    check_service_health "prometheus" "http://localhost:9090/-/healthy"
    check_service_health "grafana" "http://localhost:3001/api/health"
    
    log_success "监控服务启动完成"
}

# 启动前端服务
start_frontend() {
    log_info "启动前端服务..."
    docker-compose -f docker-compose.integrated.yml up -d web
    
    # 等待服务启动
    log_info "等待前端服务启动..."
    sleep 15
    
    # 检查服务健康状态
    check_service_health "web" "http://localhost:3000/api/health"
    
    log_success "前端服务启动完成"
}

# 检查服务健康状态
check_service_health() {
    local service_name=$1
    local health_url=$2
    
    log_info "检查 $service_name 健康状态..."
    
    # 重试机制
    local retries=10
    local count=0
    
    while [ $count -lt $retries ]; do
        if curl -f -s "$health_url" > /dev/null 2>&1; then
            log_success "$service_name 健康检查通过"
            return 0
        fi
        
        count=$((count + 1))
        log_warning "$service_name 健康检查失败，重试 $count/$retries"
        sleep 5
    done
    
    log_error "$service_name 健康检查失败"
    return 1
}

# 显示服务状态
show_service_status() {
    log_info "显示服务状态..."
    docker-compose -f docker-compose.integrated.yml ps
    
    echo ""
    log_info "服务访问地址:"
    echo "  - 前端应用: http://localhost:3000"
    echo "  - API网关: http://localhost:8000"
    echo "  - 共享基础设施: http://localhost:8210"
    echo "  - Consul UI: http://localhost:8202"
    echo "  - Prometheus: http://localhost:9090"
    echo "  - Grafana: http://localhost:3001 (admin/admin)"
    echo "  - MySQL: localhost:8200"
    echo "  - Redis: localhost:8201"
    echo "  - Neo4j: http://localhost:8203"
    echo "  - PostgreSQL: localhost:8205"
}

# 主函数
main() {
    log_info "开始JobFirst集成部署..."
    
    # 检查环境
    check_docker
    check_docker_compose
    
    # 创建目录
    create_directories
    
    # 停止现有服务
    stop_existing_services
    
    # 构建镜像
    build_images
    
    # 启动服务（按顺序）
    start_infrastructure
    start_shared_infrastructure
    start_gateway
    start_business_services
    start_monitoring
    start_frontend
    
    # 显示状态
    show_service_status
    
    log_success "JobFirst集成部署完成！"
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 执行主函数
main "$@"
