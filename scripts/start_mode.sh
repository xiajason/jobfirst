#!/bin/bash

# JobFirst 统一模式管理脚本
# 支持基础模式、增强模式、集成模式的启动和管理

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 模式配置
MODES=("basic" "enhanced" "integrated")
DEFAULT_MODE="basic"

# 显示帮助信息
show_help() {
    echo -e "${CYAN}JobFirst 统一模式管理脚本${NC}"
    echo ""
    echo "用法: $0 [模式] [选项]"
    echo ""
    echo "模式:"
    echo "  basic     基础模式 - 最小化服务集合 (默认)"
    echo "  enhanced  增强模式 - 增加AI/推荐服务"
    echo "  integrated 集成模式 - 全量服务+监控追踪"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -f, --force    强制重启，不询问确认"
    echo "  -c, --clean    清理现有容器和数据"
    echo "  -b, --build    重新构建镜像"
    echo "  -t, --test     启动后运行测试"
    echo ""
    echo "示例:"
    echo "  $0 basic              # 启动基础模式"
    echo "  $0 enhanced -f        # 强制启动增强模式"
    echo "  $0 integrated -c -b   # 清理并重新构建集成模式"
    echo ""
}

# 显示模式信息
show_mode_info() {
    local mode=$1
    echo -e "${BLUE}=== JobFirst $mode 模式信息 ===${NC}"
    
    case $mode in
        "basic")
            echo "📋 服务数量: 9个"
            echo "🔧 功能: JWT认证、CORS、API版本控制、服务发现"
            echo "💾 内存需求: ~2GB"
            echo "⚡ 启动时间: 2-3分钟"
            echo "🎯 适用场景: 开发测试、概念验证、小规模部署"
            ;;
        "enhanced")
            echo "📋 服务数量: 13个"
            echo "🔧 功能: 基础功能 + AI服务、图数据库、智能推荐"
            echo "💾 内存需求: ~4GB"
            echo "⚡ 启动时间: 5-7分钟"
            echo "🎯 适用场景: 生产环境、中等规模、需要AI功能"
            ;;
        "integrated")
            echo "📋 服务数量: 20个"
            echo "🔧 功能: 增强功能 + 监控追踪、企业级服务、多租户"
            echo "💾 内存需求: ~8GB"
            echo "⚡ 启动时间: 10-15分钟"
            echo "🎯 适用场景: 大型企业、高可用性、完整监控"
            ;;
    esac
    echo ""
}

# 检查Docker状态
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker未运行，请先启动Docker${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker运行正常${NC}"
}

# 检查系统资源
check_resources() {
    local mode=$1
    
    # 检查可用内存
    local available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    local required_mem=0
    
    case $mode in
        "basic") required_mem=2048 ;;
        "enhanced") required_mem=4096 ;;
        "integrated") required_mem=8192 ;;
    esac
    
    if [ $available_mem -lt $required_mem ]; then
        echo -e "${YELLOW}⚠️  警告: 可用内存不足${NC}"
        echo "   需要: ${required_mem}MB, 可用: ${available_mem}MB"
        echo -e "${YELLOW}   建议增加内存或关闭其他应用${NC}"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ 系统资源检查通过${NC}"
}

# 停止现有服务
stop_existing_services() {
    echo -e "${YELLOW}🛑 停止现有服务...${NC}"
    
    # 尝试停止所有可能的compose文件
    cd "$PROJECT_ROOT"
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.enhanced.yml down 2>/dev/null || true
    docker-compose -f docker-compose.integrated.yml down 2>/dev/null || true
    
    echo -e "${GREEN}✅ 现有服务已停止${NC}"
}

# 清理容器和数据
clean_environment() {
    echo -e "${YELLOW}🧹 清理环境...${NC}"
    
    # 停止所有相关容器
    docker stop $(docker ps -q --filter "name=jobfirst-*") 2>/dev/null || true
    docker rm $(docker ps -aq --filter "name=jobfirst-*") 2>/dev/null || true
    
    # 清理网络
    docker network prune -f
    
    # 清理未使用的镜像
    docker image prune -f
    
    echo -e "${GREEN}✅ 环境清理完成${NC}"
}

# 构建镜像
build_images() {
    local mode=$1
    echo -e "${YELLOW}🔨 构建镜像...${NC}"
    
    cd "$PROJECT_ROOT"
    
    case $mode in
        "basic")
            # 构建基础服务镜像
            docker-compose build
            ;;
        "enhanced")
            # 构建增强网关
            docker build -f backend/gateway/Dockerfile.complete -t jobfirst-enhanced-gateway backend/gateway 2>/dev/null || true
            # 构建其他服务
            docker-compose -f docker-compose.enhanced.yml build
            ;;
        "integrated")
            # 构建所有服务
            docker-compose -f docker-compose.integrated.yml build
            ;;
    esac
    
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 启动服务
start_services() {
    local mode=$1
    echo -e "${YELLOW}🚀 启动 $mode 模式服务...${NC}"
    
    cd "$PROJECT_ROOT"
    
    case $mode in
        "basic")
            docker-compose up -d
            ;;
        "enhanced")
            docker-compose -f docker-compose.enhanced.yml up -d
            ;;
        "integrated")
            docker-compose -f docker-compose.integrated.yml up -d
            ;;
    esac
    
    echo -e "${GREEN}✅ 服务启动完成${NC}"
}

# 等待服务就绪
wait_for_services() {
    local mode=$1
    echo -e "${YELLOW}⏳ 等待服务就绪...${NC}"
    
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 网关服务就绪${NC}"
            break
        fi
        
        echo "等待网关启动... ($attempt/$max_attempts)"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "${RED}❌ 服务启动超时${NC}"
        return 1
    fi
}

# 显示服务状态
show_service_status() {
    local mode=$1
    echo -e "${BLUE}📊 服务状态:${NC}"
    
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep jobfirst || true
    
    echo ""
    echo -e "${BLUE}🔗 访问地址:${NC}"
    echo "   🌐 网关地址: http://localhost:8080"
    echo "   📋 Consul UI: http://localhost:8202"
    echo "   🗄️  MySQL: localhost:8200"
    echo "   🔴 Redis: localhost:8201"
    
    case $mode in
        "enhanced"|"integrated")
            echo "   🐘 PostgreSQL: localhost:8203"
            echo "   🕸️  Neo4j: http://localhost:8204"
            ;;
    esac
    
    case $mode in
        "integrated")
            echo "   📈 Prometheus: http://localhost:9090"
            echo "   📊 Grafana: http://localhost:3000"
            echo "   🔍 Jaeger: http://localhost:16686"
            ;;
    esac
}

# 运行测试
run_tests() {
    local mode=$1
    echo -e "${YELLOW}🧪 运行功能测试...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # 等待服务完全启动
    sleep 10
    
    # 运行基础测试
    if [ -f "test_auth_cors.js" ]; then
        echo "运行认证和CORS测试..."
        node test_auth_cors.js || echo -e "${YELLOW}⚠️  测试部分失败，但服务已启动${NC}"
    fi
    
    # 运行健康检查
    echo "运行健康检查..."
    curl -s http://localhost:8080/health | jq . 2>/dev/null || echo "健康检查响应: $(curl -s http://localhost:8080/health)"
    
    echo -e "${GREEN}✅ 测试完成${NC}"
}

# 主函数
main() {
    # 解析参数
    local mode="$DEFAULT_MODE"
    local force=false
    local clean=false
    local build=false
    local test=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            basic|enhanced|integrated)
                mode="$1"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -c|--clean)
                clean=true
                shift
                ;;
            -b|--build)
                build=true
                shift
                ;;
            -t|--test)
                test=true
                shift
                ;;
            *)
                echo -e "${RED}❌ 未知参数: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 验证模式
    if [[ ! " ${MODES[@]} " =~ " ${mode} " ]]; then
        echo -e "${RED}❌ 无效的模式: $mode${NC}"
        echo "可用模式: ${MODES[*]}"
        exit 1
    fi
    
    # 显示启动信息
    echo -e "${CYAN}🚀 启动 JobFirst $mode 模式${NC}"
    echo ""
    
    show_mode_info "$mode"
    
    # 确认操作
    if [ "$force" != true ]; then
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "操作已取消"
            exit 0
        fi
    fi
    
    # 执行启动流程
    check_docker
    check_resources "$mode"
    
    if [ "$clean" = true ]; then
        stop_existing_services
        clean_environment
    else
        stop_existing_services
    fi
    
    if [ "$build" = true ]; then
        build_images "$mode"
    fi
    
    start_services "$mode"
    wait_for_services "$mode"
    show_service_status "$mode"
    
    if [ "$test" = true ]; then
        run_tests "$mode"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 JobFirst $mode 模式启动完成！${NC}"
    echo ""
    echo -e "${CYAN}💡 提示:${NC}"
    echo "   - 使用 'docker-compose logs -f' 查看日志"
    echo "   - 使用 '$0 $mode --help' 查看帮助"
    echo "   - 使用 '$0 --help' 查看所有选项"
    echo ""
}

# 运行主函数
main "$@"
