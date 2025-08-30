#!/bin/bash

# 测试环境部署脚本
set -e

echo "🚀 开始部署到测试环境..."

# 环境变量
STAGING_HOST="${STAGING_HOST:-localhost}"
STAGING_USER="${STAGING_USER:-ubuntu}"
STAGING_PATH="${STAGING_PATH:-/opt/jobfirst/staging}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查必要的环境变量
check_env() {
    log_info "检查环境变量..."
    
    if [ -z "$STAGING_HOST" ]; then
        log_error "STAGING_HOST 环境变量未设置"
        exit 1
    fi
    
    if [ -z "$DOCKER_REGISTRY" ]; then
        log_error "DOCKER_REGISTRY 环境变量未设置"
        exit 1
    fi
    
    log_info "环境变量检查通过"
}

# 备份当前版本
backup_current() {
    log_info "备份当前版本..."
    
    ssh $STAGING_USER@$STAGING_HOST << EOF
        if [ -d "$STAGING_PATH" ]; then
            sudo cp -r $STAGING_PATH ${STAGING_PATH}_backup_\$(date +%Y%m%d_%H%M%S)
            log_info "备份完成: ${STAGING_PATH}_backup_\$(date +%Y%m%d_%H%M%S)"
        fi
EOF
}

# 停止服务
stop_services() {
    log_info "停止现有服务..."
    
    ssh $STAGING_USER@$STAGING_HOST << EOF
        cd $STAGING_PATH
        
        # 停止所有容器
        docker-compose -f docker-compose.staging.yml down || true
        
        # 等待服务完全停止
        sleep 10
        
        log_info "服务已停止"
EOF
}

# 拉取最新镜像
pull_images() {
    log_info "拉取最新镜像..."
    
    ssh $STAGING_USER@$STAGING_HOST << EOF
        cd $STAGING_PATH
        
        # 拉取所有微服务镜像
        docker pull $DOCKER_REGISTRY/jobfirst/user:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/gateway:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/resume:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/points:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/statistics:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/storage:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/admin:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/enterprise:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/personal:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/resource:latest || true
        docker pull $DOCKER_REGISTRY/jobfirst/open:latest || true
        
        log_info "镜像拉取完成"
EOF
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    ssh $STAGING_USER@$STAGING_HOST << EOF
        cd $STAGING_PATH
        
        # 启动基础设施服务
        docker-compose -f docker-compose.staging.yml up -d mysql redis consul neo4j
        
        # 等待基础设施服务就绪
        sleep 30
        
        # 启动微服务
        docker-compose -f docker-compose.staging.yml up -d
        
        log_info "服务启动完成"
EOF
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "健康检查尝试 $attempt/$max_attempts"
        
        # 检查网关服务
        if curl -f http://$STAGING_HOST:8080/health > /dev/null 2>&1; then
            log_info "网关服务健康检查通过"
        else
            log_warn "网关服务健康检查失败"
            if [ $attempt -eq $max_attempts ]; then
                log_error "健康检查失败，部署可能有问题"
                return 1
            fi
            sleep 10
            attempt=$((attempt + 1))
            continue
        fi
        
        # 检查用户服务
        if curl -f http://$STAGING_HOST:8081/health > /dev/null 2>&1; then
            log_info "用户服务健康检查通过"
        else
            log_warn "用户服务健康检查失败"
        fi
        
        # 检查其他关键服务
        services=("8086" "8087" "8088" "8097" "6001" "8002" "8003" "9002" "9006")
        for port in "${services[@]}"; do
            if curl -f http://$STAGING_HOST:$port/health > /dev/null 2>&1; then
                log_info "端口 $port 服务健康检查通过"
            else
                log_warn "端口 $port 服务健康检查失败"
            fi
        done
        
        log_info "所有服务健康检查完成"
        break
    done
}

# 清理旧镜像
cleanup_images() {
    log_info "清理旧镜像..."
    
    ssh $STAGING_USER@$STAGING_HOST << EOF
        # 删除未使用的镜像
        docker image prune -f
        
        # 删除超过7天的备份
        find $STAGING_PATH -name "*_backup_*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
        
        log_info "清理完成"
EOF
}

# 主函数
main() {
    log_info "开始测试环境部署流程..."
    
    check_env
    backup_current
    stop_services
    pull_images
    start_services
    
    # 等待服务启动
    sleep 30
    
    if health_check; then
        log_info "✅ 部署成功！"
        cleanup_images
    else
        log_error "❌ 部署失败，开始回滚..."
        rollback
        exit 1
    fi
}

# 回滚函数
rollback() {
    log_warn "开始回滚..."
    
    ssh $STAGING_USER@$STAGING_HOST << EOF
        cd $STAGING_PATH
        
        # 停止当前服务
        docker-compose -f docker-compose.staging.yml down
        
        # 找到最新的备份
        latest_backup=\$(find ${STAGING_PATH}_backup_* -type d | sort | tail -1)
        
        if [ -n "\$latest_backup" ]; then
            # 恢复备份
            sudo rm -rf $STAGING_PATH
            sudo cp -r "\$latest_backup" $STAGING_PATH
            
            # 重新启动服务
            cd $STAGING_PATH
            docker-compose -f docker-compose.staging.yml up -d
            
            log_info "回滚完成"
        else
            log_error "没有找到可用的备份"
        fi
EOF
}

# 执行主函数
main "$@"
