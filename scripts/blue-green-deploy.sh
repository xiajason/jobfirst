#!/bin/bash

# 蓝绿部署脚本 - 生产环境
set -e

echo "🚀 开始蓝绿部署到生产环境..."

# 环境变量
PROD_HOST="${PROD_HOST:-localhost}"
PROD_USER="${PROD_USER:-ubuntu}"
PROD_PATH="${PROD_PATH:-/opt/jobfirst/production}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
BLUE_PORT="${BLUE_PORT:-8080}"
GREEN_PORT="${GREEN_PORT:-8081}"
LOAD_BALANCER_PORT="${LOAD_BALANCER_PORT:-80}"

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
    echo -e "${BLUE}[BLUE]${NC} $1"
}

log_green() {
    echo -e "${GREEN}[GREEN]${NC} $1"
}

# 检查必要的环境变量
check_env() {
    log_info "检查环境变量..."
    
    if [ -z "$PROD_HOST" ]; then
        log_error "PROD_HOST 环境变量未设置"
        exit 1
    fi
    
    if [ -z "$DOCKER_REGISTRY" ]; then
        log_error "DOCKER_REGISTRY 环境变量未设置"
        exit 1
    fi
    
    log_info "环境变量检查通过"
}

# 确定当前活跃环境
determine_active_environment() {
    log_info "确定当前活跃环境..."
    
    ssh $PROD_USER@$PROD_HOST << EOF
        # 检查负载均衡器配置
        if curl -f http://localhost:$LOAD_BALANCER_PORT/health > /dev/null 2>&1; then
            # 检查当前路由到哪个端口
            current_port=\$(curl -s http://localhost:$LOAD_BALANCER_PORT/status | grep -o 'port=[0-9]*' | cut -d'=' -f2)
            
            if [ "\$current_port" = "$BLUE_PORT" ]; then
                echo "BLUE" > /tmp/active_env
                echo "GREEN" > /tmp/target_env
            else
                echo "GREEN" > /tmp/active_env
                echo "BLUE" > /tmp/target_env
            fi
        else
            # 默认使用蓝环境
            echo "BLUE" > /tmp/active_env
            echo "GREEN" > /tmp/target_env
        fi
EOF
    
    # 获取环境信息
    ACTIVE_ENV=$(ssh $PROD_USER@$PROD_HOST "cat /tmp/active_env")
    TARGET_ENV=$(ssh $PROD_USER@$PROD_HOST "cat /tmp/target_env")
    
    log_info "当前活跃环境: $ACTIVE_ENV"
    log_info "目标部署环境: $TARGET_ENV"
}

# 部署到目标环境
deploy_to_target() {
    local target_env=$1
    local target_port=$2
    
    log_info "部署到 $target_env 环境 (端口: $target_port)..."
    
    ssh $PROD_USER@$PROD_HOST << EOF
        cd $PROD_PATH/$target_env
        
        # 停止现有服务
        docker-compose -f docker-compose.prod.yml down || true
        
        # 拉取最新镜像
        docker pull $DOCKER_REGISTRY/jobfirst/user:latest
        docker pull $DOCKER_REGISTRY/jobfirst/gateway:latest
        docker pull $DOCKER_REGISTRY/jobfirst/resume:latest
        docker pull $DOCKER_REGISTRY/jobfirst/points:latest
        docker pull $DOCKER_REGISTRY/jobfirst/statistics:latest
        docker pull $DOCKER_REGISTRY/jobfirst/storage:latest
        docker pull $DOCKER_REGISTRY/jobfirst/admin:latest
        docker pull $DOCKER_REGISTRY/jobfirst/enterprise:latest
        docker pull $DOCKER_REGISTRY/jobfirst/personal:latest
        docker pull $DOCKER_REGISTRY/jobfirst/resource:latest
        docker pull $DOCKER_REGISTRY/jobfirst/open:latest
        
        # 更新环境变量
        export GATEWAY_PORT=$target_port
        
        # 启动服务
        docker-compose -f docker-compose.prod.yml up -d
        
        log_info "$target_env 环境部署完成"
EOF
}

# 健康检查
health_check() {
    local target_env=$1
    local target_port=$2
    
    log_info "检查 $target_env 环境健康状态..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "健康检查尝试 $attempt/$max_attempts"
        
        # 检查网关服务
        if curl -f http://$PROD_HOST:$target_port/health > /dev/null 2>&1; then
            log_info "$target_env 网关服务健康检查通过"
        else
            log_warn "$target_env 网关服务健康检查失败"
            if [ $attempt -eq $max_attempts ]; then
                log_error "$target_env 环境健康检查失败"
                return 1
            fi
            sleep 10
            attempt=$((attempt + 1))
            continue
        fi
        
        # 检查关键API
        if curl -f http://$PROD_HOST:$target_port/api/v2/jobs/ > /dev/null 2>&1; then
            log_info "$target_env API健康检查通过"
        else
            log_warn "$target_env API健康检查失败"
        fi
        
        log_info "$target_env 环境健康检查完成"
        break
    done
}

# 切换流量
switch_traffic() {
    local target_env=$1
    local target_port=$2
    
    log_info "切换流量到 $target_env 环境..."
    
    ssh $PROD_USER@$PROD_HOST << EOF
        # 更新负载均衡器配置
        sudo tee /etc/nginx/sites-available/jobfirst << EOF_NGINX
server {
    listen $LOAD_BALANCER_PORT;
    server_name _;
    
    location / {
        proxy_pass http://localhost:$target_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF_NGINX

        # 重新加载nginx配置
        sudo nginx -t && sudo systemctl reload nginx
        
        log_info "流量切换完成"
EOF
}

# 验证部署
verify_deployment() {
    local target_env=$1
    
    log_info "验证 $target_env 环境部署..."
    
    # 等待一段时间让流量稳定
    sleep 30
    
    # 检查关键指标
    ssh $PROD_USER@$PROD_HOST << EOF
        # 检查服务状态
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # 检查日志
        docker logs jobfirst-gateway --tail 50
        
        # 检查系统资源
        df -h
        free -h
        top -bn1 | head -20
EOF
    
    log_info "$target_env 环境验证完成"
}

# 清理旧环境
cleanup_old_environment() {
    local old_env=$1
    
    log_info "清理 $old_env 环境..."
    
    ssh $PROD_USER@$PROD_HOST << EOF
        cd $PROD_PATH/$old_env
        
        # 停止服务
        docker-compose -f docker-compose.prod.yml down
        
        # 清理未使用的镜像
        docker image prune -f
        
        log_info "$old_env 环境清理完成"
EOF
}

# 回滚函数
rollback() {
    local target_env=$1
    local active_env=$2
    
    log_error "部署失败，开始回滚..."
    
    # 切换回原环境
    if [ "$target_env" = "BLUE" ]; then
        switch_traffic "GREEN" "$GREEN_PORT"
    else
        switch_traffic "BLUE" "$BLUE_PORT"
    fi
    
    # 清理目标环境
    cleanup_old_environment "$target_env"
    
    log_warn "回滚完成，系统已恢复到 $active_env 环境"
}

# 主函数
main() {
    log_info "开始蓝绿部署流程..."
    
    check_env
    determine_active_environment
    
    # 确定目标端口
    if [ "$TARGET_ENV" = "BLUE" ]; then
        TARGET_PORT=$BLUE_PORT
    else
        TARGET_PORT=$GREEN_PORT
    fi
    
    log_info "目标环境: $TARGET_ENV (端口: $TARGET_PORT)"
    
    # 部署到目标环境
    deploy_to_target "$TARGET_ENV" "$TARGET_PORT"
    
    # 等待服务启动
    sleep 30
    
    # 健康检查
    if health_check "$TARGET_ENV" "$TARGET_PORT"; then
        log_info "✅ $TARGET_ENV 环境部署成功！"
        
        # 切换流量
        switch_traffic "$TARGET_ENV" "$TARGET_PORT"
        
        # 验证部署
        verify_deployment "$TARGET_ENV"
        
        # 清理旧环境
        cleanup_old_environment "$ACTIVE_ENV"
        
        log_info "🎉 蓝绿部署完成！新版本已上线"
    else
        log_error "❌ $TARGET_ENV 环境部署失败"
        rollback "$TARGET_ENV" "$ACTIVE_ENV"
        exit 1
    fi
}

# 执行主函数
main "$@"
