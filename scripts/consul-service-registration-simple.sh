#!/bin/bash

# JobFirst Consul服务注册脚本 - 简化版本
# 用于注册所有微服务到Consul服务发现中心

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

# Consul配置
CONSUL_ADDRESS="http://localhost:8202"
CONSUL_DATACENTER="dc1"

# 服务列表
SERVICES=(
    "shared-infrastructure:8210:shared,infrastructure,jobfirst,core:version=1.0.0,type=infrastructure"
    "gateway:8000:gateway,api,router,jobfirst:version=1.0.0,type=gateway"
    "user-service:8001:user,auth,api,jobfirst:version=1.0.0,type=business"
    "resume-service:8002:resume,document,api,jobfirst:version=1.0.0,type=business"
    "personal-service:8003:personal,user,api,jobfirst:version=1.0.0,type=business"
    "points-service:8004:points,reward,api,jobfirst:version=1.0.0,type=business"
    "statistics-service:8005:statistics,analytics,api,jobfirst:version=1.0.0,type=business"
    "storage-service:8006:storage,file,api,jobfirst:version=1.0.0,type=business"
    "resource-service:8007:resource,file,api,jobfirst:version=1.0.0,type=business"
    "enterprise-service:8008:enterprise,company,api,jobfirst:version=1.0.0,type=business"
    "open-service:8009:open,api,public,jobfirst:version=1.0.0,type=business"
    "admin-service:8010:admin,management,api,jobfirst:version=1.0.0,type=management"
    "ai-service:8206:ai,machine-learning,api,jobfirst:version=1.0.0,type=ai"
    "mysql:8200:database,mysql,jobfirst:version=8.0,type=database"
    "redis:8201:cache,redis,jobfirst:version=7.0,type=cache"
    "neo4j:8204:database,neo4j,graph,jobfirst:version=5.15,type=database"
    "postgresql:8203:database,postgresql,jobfirst:version=15,type=database"
)

# 检查Consul连接
check_consul_connection() {
    log_info "检查Consul连接..."
    if curl -f -s "$CONSUL_ADDRESS/v1/status/leader" > /dev/null 2>&1; then
        log_success "Consul连接正常"
        return 0
    else
        log_error "无法连接到Consul: $CONSUL_ADDRESS"
        return 1
    fi
}

# 注册服务到Consul
register_service() {
    local service_info=$1
    local service_name=$(echo $service_info | cut -d':' -f1)
    local port=$(echo $service_info | cut -d':' -f2)
    local tags=$(echo $service_info | cut -d':' -f3)
    local meta=$(echo $service_info | cut -d':' -f4)
    
    log_info "注册服务: $service_name (端口: $port)"
    
    # 构建服务注册JSON
    local service_json=$(cat <<EOF
{
    "ID": "jobfirst-$service_name",
    "Name": "$service_name",
    "Address": "localhost",
    "Port": $port,
    "Tags": ["$tags"],
    "Meta": {
        "version": "$(echo $meta | cut -d',' -f1 | cut -d'=' -f2)",
        "type": "$(echo $meta | cut -d',' -f2 | cut -d'=' -f2)"
    },
    "Check": {
        "HTTP": "http://localhost:$port/health",
        "Interval": "10s",
        "Timeout": "5s",
        "DeregisterCriticalServiceAfter": "30s"
    }
}
EOF
)
    
    # 注册服务
    local response=$(curl -s -X PUT \
        -H "Content-Type: application/json" \
        -d "$service_json" \
        "$CONSUL_ADDRESS/v1/agent/service/register")
    
    if [ $? -eq 0 ]; then
        log_success "服务 $service_name 注册成功"
        return 0
    else
        log_error "服务 $service_name 注册失败: $response"
        return 1
    fi
}

# 注销服务
deregister_service() {
    local service_name=$1
    
    log_info "注销服务: $service_name"
    
    local response=$(curl -s -X PUT \
        "$CONSUL_ADDRESS/v1/agent/service/deregister/jobfirst-$service_name")
    
    if [ $? -eq 0 ]; then
        log_success "服务 $service_name 注销成功"
        return 0
    else
        log_warning "服务 $service_name 注销失败: $response"
        return 1
    fi
}

# 检查服务健康状态
check_service_health() {
    local service_info=$1
    local service_name=$(echo $service_info | cut -d':' -f1)
    local port=$(echo $service_info | cut -d':' -f2)
    
    log_info "检查服务健康状态: $service_name"
    
    # 重试机制
    local retries=5
    local count=0
    
    while [ $count -lt $retries ]; do
        if curl -f -s "http://localhost:$port/health" > /dev/null 2>&1; then
            log_success "服务 $service_name 健康检查通过"
            return 0
        fi
        
        count=$((count + 1))
        log_warning "服务 $service_name 健康检查失败，重试 $count/$retries"
        sleep 2
    done
    
    log_error "服务 $service_name 健康检查失败"
    return 1
}

# 注册所有服务
register_all_services() {
    log_info "开始注册所有服务到Consul..."
    
    local failed_registrations=0
    
    for service_info in "${SERVICES[@]}"; do
        local service_name=$(echo $service_info | cut -d':' -f1)
        
        # 检查服务是否运行
        if check_service_health "$service_info"; then
            if register_service "$service_info"; then
                log_success "✅ $service_name 注册成功"
            else
                log_error "❌ $service_name 注册失败"
                ((failed_registrations++))
            fi
        else
            log_warning "⚠️  $service_name 未运行，跳过注册"
        fi
    done
    
    if [ $failed_registrations -eq 0 ]; then
        log_success "所有服务注册完成！"
    else
        log_error "有 $failed_registrations 个服务注册失败"
        return 1
    fi
}

# 注销所有服务
deregister_all_services() {
    log_info "开始注销所有服务..."
    
    for service_info in "${SERVICES[@]}"; do
        local service_name=$(echo $service_info | cut -d':' -f1)
        deregister_service "$service_name"
    done
    
    log_success "所有服务注销完成！"
}

# 显示服务状态
show_service_status() {
    log_info "显示Consul中的服务状态..."
    
    echo ""
    log_info "=== 已注册的服务 ==="
    curl -s "$CONSUL_ADDRESS/v1/catalog/services" | jq -r 'to_entries[] | "\(.key): \(.value | join(", "))"'
    
    echo ""
    log_info "=== 服务健康状态 ==="
    curl -s "$CONSUL_ADDRESS/v1/health/state/any" | jq -r '.[] | "\(.ServiceName): \(.Status)"'
}

# 更新服务配置
update_service_config() {
    local service_info=$1
    local service_name=$(echo $service_info | cut -d':' -f1)
    local port=$(echo $service_info | cut -d':' -f2)
    local tags=$(echo $service_info | cut -d':' -f3)
    local meta=$(echo $service_info | cut -d':' -f4)
    
    log_info "更新服务配置: $service_name"
    
    # 构建配置更新JSON
    local config_json=$(cat <<EOF
{
    "ID": "jobfirst-$service_name",
    "Name": "$service_name",
    "Address": "localhost",
    "Port": $port,
    "Tags": ["$tags"],
    "Meta": {
        "version": "$(echo $meta | cut -d',' -f1 | cut -d'=' -f2)",
        "type": "$(echo $meta | cut -d',' -f2 | cut -d'=' -f2)",
        "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    },
    "Check": {
        "HTTP": "http://localhost:$port/health",
        "Interval": "10s",
        "Timeout": "5s",
        "DeregisterCriticalServiceAfter": "30s"
    }
}
EOF
)
    
    # 更新服务配置
    local response=$(curl -s -X PUT \
        -H "Content-Type: application/json" \
        -d "$config_json" \
        "$CONSUL_ADDRESS/v1/agent/service/register")
    
    if [ $? -eq 0 ]; then
        log_success "服务 $service_name 配置更新成功"
        return 0
    else
        log_error "服务 $service_name 配置更新失败: $response"
        return 1
    fi
}

# 更新所有服务配置
update_all_service_configs() {
    log_info "开始更新所有服务配置..."
    
    local failed_updates=0
    
    for service_info in "${SERVICES[@]}"; do
        if update_service_config "$service_info"; then
            local service_name=$(echo $service_info | cut -d':' -f1)
            log_success "✅ $service_name 配置更新成功"
        else
            local service_name=$(echo $service_info | cut -d':' -f1)
            log_error "❌ $service_name 配置更新失败"
            ((failed_updates++))
        fi
    done
    
    if [ $failed_updates -eq 0 ]; then
        log_success "所有服务配置更新完成！"
    else
        log_error "有 $failed_updates 个服务配置更新失败"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "JobFirst Consul服务注册脚本 - 简化版本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -r, --register      注册所有服务"
    echo "  -d, --deregister    注销所有服务"
    echo "  -u, --update        更新所有服务配置"
    echo "  -s, --status        显示服务状态"
    echo "  -c, --check         检查服务健康状态"
    echo ""
    echo "示例:"
    echo "  $0 -r               注册所有服务"
    echo "  $0 -d               注销所有服务"
    echo "  $0 -u               更新所有服务配置"
    echo "  $0 -s               显示服务状态"
    echo "  $0 -c               检查服务健康状态"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--register)
            check_consul_connection
            register_all_services
            show_service_status
            ;;
        -d|--deregister)
            check_consul_connection
            deregister_all_services
            ;;
        -u|--update)
            check_consul_connection
            update_all_service_configs
            show_service_status
            ;;
        -s|--status)
            check_consul_connection
            show_service_status
            ;;
        -c|--check)
            check_consul_connection
            for service_info in "${SERVICES[@]}"; do
                check_service_health "$service_info"
            done
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
