#!/bin/bash

# JobFirst 服务健康检查脚本

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

# 检查服务健康状态
check_service() {
    local service_name=$1
    local health_url=$2
    local description=$3
    
    log_info "检查 $service_name ($description)..."
    
    if curl -f -s "$health_url" > /dev/null 2>&1; then
        log_success "$service_name 健康"
        return 0
    else
        log_error "$service_name 不健康"
        return 1
    fi
}

# 检查Docker容器状态
check_container() {
    local container_name=$1
    local description=$2
    
    log_info "检查容器 $container_name ($description)..."
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
        log_success "$container_name 运行正常"
        return 0
    else
        log_error "$container_name 未运行或状态异常"
        return 1
    fi
}

# 检查端口是否开放
check_port() {
    local port=$1
    local description=$2
    
    log_info "检查端口 $port ($description)..."
    
    if netstat -an | grep -q ":$port.*LISTEN"; then
        log_success "端口 $port 开放"
        return 0
    else
        log_error "端口 $port 未开放"
        return 1
    fi
}

# 主健康检查函数
main_health_check() {
    log_info "开始JobFirst系统健康检查..."
    
    local failed_checks=0
    
    # 检查Docker容器状态
    echo ""
    log_info "=== Docker容器状态检查 ==="
    
    check_container "jobfirst-mysql" "MySQL数据库" || ((failed_checks++))
    check_container "jobfirst-redis" "Redis缓存" || ((failed_checks++))
    check_container "jobfirst-consul" "Consul服务发现" || ((failed_checks++))
    check_container "jobfirst-neo4j" "Neo4j图数据库" || ((failed_checks++))
    check_container "jobfirst-postgresql" "PostgreSQL数据库" || ((failed_checks++))
    check_container "jobfirst-shared-infrastructure" "共享基础设施" || ((failed_checks++))
    check_container "jobfirst-gateway" "API网关" || ((failed_checks++))
    check_container "jobfirst-user" "用户服务" || ((failed_checks++))
    check_container "jobfirst-resume" "简历服务" || ((failed_checks++))
    check_container "jobfirst-ai" "AI服务" || ((failed_checks++))
    check_container "jobfirst-prometheus" "Prometheus监控" || ((failed_checks++))
    check_container "jobfirst-grafana" "Grafana监控面板" || ((failed_checks++))
    check_container "jobfirst-web" "前端Web应用" || ((failed_checks++))
    
    # 检查服务健康状态
    echo ""
    log_info "=== 服务健康状态检查 ==="
    
    check_service "shared-infrastructure" "http://localhost:8210/health" "共享基础设施" || ((failed_checks++))
    check_service "gateway" "http://localhost:8000/health" "API网关" || ((failed_checks++))
    check_service "user-service" "http://localhost:8001/health" "用户服务" || ((failed_checks++))
    check_service "resume-service" "http://localhost:8002/health" "简历服务" || ((failed_checks++))
    check_service "ai-service" "http://localhost:8206/health" "AI服务" || ((failed_checks++))
    check_service "prometheus" "http://localhost:9090/-/healthy" "Prometheus" || ((failed_checks++))
    check_service "grafana" "http://localhost:3001/api/health" "Grafana" || ((failed_checks++))
    check_service "web" "http://localhost:3000/api/health" "前端Web" || ((failed_checks++))
    
    # 检查端口状态
    echo ""
    log_info "=== 端口状态检查 ==="
    
    check_port "8200" "MySQL数据库" || ((failed_checks++))
    check_port "8201" "Redis缓存" || ((failed_checks++))
    check_port "8202" "Consul服务发现" || ((failed_checks++))
    check_port "8203" "Neo4j图数据库" || ((failed_checks++))
    check_port "8205" "PostgreSQL数据库" || ((failed_checks++))
    check_port "8210" "共享基础设施" || ((failed_checks++))
    check_port "8000" "API网关" || ((failed_checks++))
    check_port "8001" "用户服务" || ((failed_checks++))
    check_port "8002" "简历服务" || ((failed_checks++))
    check_port "8206" "AI服务" || ((failed_checks++))
    check_port "9090" "Prometheus监控" || ((failed_checks++))
    check_port "3001" "Grafana监控面板" || ((failed_checks++))
    check_port "3000" "前端Web应用" || ((failed_checks++))
    
    # 检查Consul服务注册
    echo ""
    log_info "=== Consul服务注册检查 ==="
    
    if curl -f -s "http://localhost:8202/v1/catalog/services" | grep -q "shared-infrastructure"; then
        log_success "共享基础设施已注册到Consul"
    else
        log_error "共享基础设施未注册到Consul"
        ((failed_checks++))
    fi
    
    if curl -f -s "http://localhost:8202/v1/catalog/services" | grep -q "gateway"; then
        log_success "API网关已注册到Consul"
    else
        log_error "API网关未注册到Consul"
        ((failed_checks++))
    fi
    
    # 检查数据库连接
    echo ""
    log_info "=== 数据库连接检查 ==="
    
    # MySQL连接检查
    if docker exec jobfirst-mysql mysqladmin ping -h localhost -u jobfirst -pjobfirst123 > /dev/null 2>&1; then
        log_success "MySQL连接正常"
    else
        log_error "MySQL连接失败"
        ((failed_checks++))
    fi
    
    # Redis连接检查
    if docker exec jobfirst-redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis连接正常"
    else
        log_error "Redis连接失败"
        ((failed_checks++))
    fi
    
    # 显示检查结果
    echo ""
    log_info "=== 健康检查结果 ==="
    
    if [ $failed_checks -eq 0 ]; then
        log_success "所有检查通过！JobFirst系统运行正常"
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
    else
        log_error "有 $failed_checks 个检查失败，请检查相关服务"
        exit 1
    fi
}

# 快速健康检查
quick_health_check() {
    log_info "执行快速健康检查..."
    
    local failed_checks=0
    
    # 检查关键服务
    check_service "shared-infrastructure" "http://localhost:8210/health" "共享基础设施" || ((failed_checks++))
    check_service "gateway" "http://localhost:8000/health" "API网关" || ((failed_checks++))
    check_service "web" "http://localhost:3000/api/health" "前端Web" || ((failed_checks++))
    
    if [ $failed_checks -eq 0 ]; then
        log_success "快速健康检查通过！"
    else
        log_error "快速健康检查失败，有 $failed_checks 个服务异常"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "JobFirst 健康检查脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -q, --quick    执行快速健康检查"
    echo "  -f, --full     执行完整健康检查（默认）"
    echo ""
    echo "示例:"
    echo "  $0             执行完整健康检查"
    echo "  $0 -q          执行快速健康检查"
    echo "  $0 --help      显示帮助信息"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quick)
            quick_health_check
            ;;
        -f|--full|"")
            main_health_check
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
