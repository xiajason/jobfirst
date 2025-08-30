#!/bin/bash

# JobFirst 开发环境启动脚本
# 支持热加载和后台运行

set -e

# 颜色定义
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    # 检查 air 是否安装
    if ! command -v air &> /dev/null; then
        log_error "air 未安装，正在安装..."
        go install github.com/air-verse/air@latest
    fi
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker 未运行，请启动 Docker"
        exit 1
    fi
    
    log_info "依赖检查完成"
}

# 启动基础设施服务
start_infrastructure() {
    log_info "启动基础设施服务..."
    
    # 检查基础设施是否已运行
    if docker ps --format "table {{.Names}}" | grep -q "jobfirst-mysql"; then
        log_warn "基础设施服务已运行，跳过启动"
        return
    fi
    
    # 启动基础设施
    docker-compose -f docker-compose.yml up -d mysql redis consul
    
    # 等待服务启动
    log_info "等待基础设施服务启动..."
    sleep 10
    
    # 检查服务状态
    if curl -s http://localhost:8202/v1/status/leader &> /dev/null; then
        log_info "Consul 启动成功"
    else
        log_error "Consul 启动失败"
        exit 1
    fi
    
    if docker exec jobfirst-redis redis-cli ping &> /dev/null; then
        log_info "Redis 启动成功"
    else
        log_error "Redis 启动失败"
        exit 1
    fi
    
    log_info "基础设施服务启动完成"
}

# 启动微服务（使用 air 热加载）
start_microservice() {
    local service_name=$1
    local service_port=$2
    local service_dir="backend/$service_name"
    
    log_info "启动 $service_name 服务 (端口: $service_port)..."
    
    # 检查端口是否被占用
    if lsof -Pi :$service_port -sTCP:LISTEN -t >/dev/null ; then
        log_warn "端口 $service_port 已被占用，停止现有进程"
        lsof -ti:$service_port | xargs kill -9
        sleep 2
    fi
    
    # 创建日志目录
    mkdir -p logs
    
    # 使用 air 启动服务（后台运行）
    cd $service_dir
    nohup air > ../../logs/${service_name}.log 2>&1 &
    cd ../..
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    if curl -s http://localhost:$service_port/health &> /dev/null; then
        log_info "$service_name 服务启动成功"
        echo $! > logs/${service_name}.pid
    else
        log_error "$service_name 服务启动失败"
        log_error "查看日志: tail -f logs/${service_name}.log"
        exit 1
    fi
}

# 启动所有微服务
start_all_services() {
    log_info "启动所有微服务..."
    
    # 创建日志目录
    mkdir -p logs
    
    # 启动各个微服务
    start_microservice "user" 8081
    start_microservice "resume" 8087
    start_microservice "admin" 8003
    start_microservice "resource" 9002
    start_microservice "personal" 6001
    start_microservice "enterprise" 8002
    start_microservice "open" 9006
    # start_microservice "blockchain" 9009  # 暂时禁用，需要复杂认证
    start_microservice "points" 8086
    start_microservice "statistics" 8097
    start_microservice "storage" 8088
    # start_microservice "common" 9001  # common是共享模块，不是独立服务
    
    # 启动网关（最后启动）
    log_info "启动 API 网关..."
    start_microservice "gateway" 8080
    
    log_info "所有微服务启动完成"
}

# 显示服务状态
show_status() {
    log_info "服务状态:"
    echo "----------------------------------------"
    
    # 基础设施服务
    echo "基础设施服务:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep jobfirst
    
    echo ""
    echo "微服务:"
    
    # 微服务状态
    services=("user:8081" "resume:8087" "admin:8003" "resource:9002" "personal:6001" "enterprise:8002" "open:9006" "points:8086" "statistics:8097" "storage:8088" "gateway:8080")
    
    for service in "${services[@]}"; do
        IFS=':' read -r name port <<< "$service"
        
        if [ -f "logs/${name}.pid" ]; then
            pid=$(cat logs/${name}.pid)
            if ps -p $pid > /dev/null 2>&1; then
                if curl -s http://localhost:$port/health &> /dev/null; then
                    echo -e "  ${GREEN}✓${NC} $name (PID: $pid, Port: $port) - 运行中"
                else
                    echo -e "  ${YELLOW}⚠${NC} $name (PID: $pid, Port: $port) - 进程存在但无响应"
                fi
            else
                echo -e "  ${RED}✗${NC} $name (Port: $port) - 已停止"
            fi
        else
            echo -e "  ${RED}✗${NC} $name (Port: $port) - 未启动"
        fi
    done
    
    echo ""
    echo "日志文件:"
    ls -la logs/*.log 2>/dev/null || echo "  暂无日志文件"
    
    echo ""
    echo "访问地址:"
    echo "  API 网关: http://localhost:8080"
    echo "  Consul UI: http://localhost:8202"
    echo "  MySQL: localhost:8200"
    echo "  Redis: localhost:8201"
}

# 停止所有服务
stop_all_services() {
    log_info "停止所有微服务..."
    
    # 停止微服务进程
    for pid_file in logs/*.pid; do
        if [ -f "$pid_file" ]; then
            service_name=$(basename "$pid_file" .pid)
            pid=$(cat "$pid_file")
            
            if ps -p $pid > /dev/null 2>&1; then
                log_info "停止 $service_name 服务 (PID: $pid)"
                kill $pid
                rm "$pid_file"
            fi
        fi
    done
    
    # 停止基础设施
    log_info "停止基础设施服务..."
    docker-compose -f docker-compose.yml down
    
    log_info "所有服务已停止"
}

# 重启服务
restart_service() {
    local service_name=$1
    local service_port=$2
    
    log_info "重启 $service_name 服务..."
    
    # 停止服务
    if [ -f "logs/${service_name}.pid" ]; then
        pid=$(cat "logs/${service_name}.pid")
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid
            rm "logs/${service_name}.pid"
        fi
    fi
    
    # 重新启动服务
    start_microservice $service_name $service_port
}

# 查看日志
view_logs() {
    local service_name=$1
    
    if [ -z "$service_name" ]; then
        log_info "可用日志文件:"
        ls -la logs/*.log 2>/dev/null || echo "暂无日志文件"
        return
    fi
    
    if [ -f "logs/${service_name}.log" ]; then
        log_info "查看 $service_name 服务日志 (Ctrl+C 退出):"
        tail -f "logs/${service_name}.log"
    else
        log_error "日志文件不存在: logs/${service_name}.log"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        "start")
            check_dependencies
            start_infrastructure
            start_all_services
            show_status
            log_info "开发环境启动完成！"
            log_info "使用 './scripts/dev-start.sh status' 查看状态"
            log_info "使用 './scripts/dev-start.sh logs <service>' 查看日志"
            ;;
        "stop")
            stop_all_services
            ;;
        "restart")
            if [ -z "$2" ]; then
                log_error "请指定要重启的服务名称"
                exit 1
            fi
            case "$2" in
                "user") restart_service "user" 8081 ;;
                "resume") restart_service "resume" 8087 ;;
                "points") restart_service "points" 8086 ;;
                "statistics") restart_service "statistics" 8097 ;;
                "storage") restart_service "storage" 8088 ;;
                "gateway") restart_service "gateway" 8080 ;;
                "personal") restart_service "personal" 6001 ;;
                "admin") restart_service "admin" 8003 ;;
                "enterprise") restart_service "enterprise" 8002 ;;
                "resource") restart_service "resource" 9002 ;;
                "open") restart_service "open" 9006 ;;
                *) log_error "未知服务: $2" ;;
            esac
            ;;
        "status")
            show_status
            ;;
        "logs")
            view_logs "$2"
            ;;
        "help"|"-h"|"--help")
            echo "JobFirst 开发环境管理脚本"
            echo ""
            echo "用法: $0 [命令] [参数]"
            echo ""
            echo "命令:"
            echo "  start                   启动所有服务（默认）"
            echo "  stop                    停止所有服务"
            echo "  restart <service>       重启指定服务"
            echo "  status                  显示服务状态"
            echo "  logs [service]          查看服务日志"
            echo "  help                    显示帮助信息"
            echo ""
            echo "服务名称: user, resume, points, statistics, storage, gateway, admin, personal, enterprise, resource, open"
            echo ""
            echo "示例:"
            echo "  $0 start                启动所有服务"
            echo "  $0 restart user         重启用户服务"
            echo "  $0 logs gateway         查看网关日志"
            ;;
        *)
            log_error "未知命令: $1"
            echo "使用 '$0 help' 查看帮助信息"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
