#!/bin/bash

# JobFirst 模式切换脚本
# 支持基础模式、增强模式、集成模式之间的平滑切换

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

# 显示帮助信息
show_help() {
    echo -e "${CYAN}JobFirst 模式切换脚本${NC}"
    echo ""
    echo "用法: $0 [源模式] [目标模式] [选项]"
    echo ""
    echo "模式:"
    echo "  basic     基础模式 - 最小化服务集合"
    echo "  enhanced  增强模式 - 增加AI/推荐服务"
    echo "  integrated 集成模式 - 全量服务+监控追踪"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -f, --force    强制切换，不询问确认"
    echo "  -b, --backup   切换前备份数据"
    echo "  -r, --restore  切换后恢复数据"
    echo "  -t, --test     切换后运行测试"
    echo ""
    echo "示例:"
    echo "  $0 basic enhanced        # 从基础模式切换到增强模式"
    echo "  $0 enhanced integrated -b # 备份并切换到集成模式"
    echo "  $0 integrated basic -f   # 强制降级到基础模式"
    echo ""
}

# 获取当前运行的模式
get_current_mode() {
    cd "$PROJECT_ROOT"
    
    # 检查哪个compose文件正在运行
    if docker-compose ps | grep -q "jobfirst-"; then
        echo "basic"
    elif docker-compose -f docker-compose.enhanced.yml ps | grep -q "jobfirst-"; then
        echo "enhanced"
    elif docker-compose -f docker-compose.integrated.yml ps | grep -q "jobfirst-"; then
        echo "integrated"
    else
        echo "none"
    fi
}

# 显示模式信息
show_mode_info() {
    local mode=$1
    local prefix=$2
    
    echo -e "${BLUE}=== $prefix $mode 模式 ===${NC}"
    
    case $mode in
        "basic")
            echo "📋 服务数量: 9个"
            echo "🔧 功能: JWT认证、CORS、API版本控制、服务发现"
            echo "💾 内存需求: ~2GB"
            ;;
        "enhanced")
            echo "📋 服务数量: 13个"
            echo "🔧 功能: 基础功能 + AI服务、图数据库、智能推荐"
            echo "💾 内存需求: ~4GB"
            ;;
        "integrated")
            echo "📋 服务数量: 20个"
            echo "🔧 功能: 增强功能 + 监控追踪、企业级服务、多租户"
            echo "💾 内存需求: ~8GB"
            ;;
    esac
    echo ""
}

# 备份数据
backup_data() {
    local source_mode=$1
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="$PROJECT_ROOT/backups/${source_mode}_${timestamp}"
    
    echo -e "${YELLOW}💾 备份 $source_mode 模式数据...${NC}"
    
    mkdir -p "$backup_dir"
    cd "$PROJECT_ROOT"
    
    case $source_mode in
        "basic")
            # 备份MySQL数据
            docker-compose exec -T mysql mysqldump -u root -pjobfirst123 jobfirst > "$backup_dir/mysql_backup.sql" 2>/dev/null || true
            # 备份Redis数据
            docker-compose exec -T redis redis-cli BGSAVE > /dev/null 2>&1 || true
            ;;
        "enhanced")
            # 备份MySQL数据
            docker-compose -f docker-compose.enhanced.yml exec -T mysql mysqldump -u root -pjobfirst123 jobfirst > "$backup_dir/mysql_backup.sql" 2>/dev/null || true
            # 备份PostgreSQL数据
            docker-compose -f docker-compose.enhanced.yml exec -T postgresql pg_dump -U jobfirst jobfirst_advanced > "$backup_dir/postgresql_backup.sql" 2>/dev/null || true
            # 备份Neo4j数据
            docker-compose -f docker-compose.enhanced.yml exec -T neo4j neo4j-admin database dump neo4j > "$backup_dir/neo4j_backup.dump" 2>/dev/null || true
            ;;
        "integrated")
            # 备份所有数据
            docker-compose -f docker-compose.integrated.yml exec -T mysql mysqldump -u root -pjobfirst123 jobfirst > "$backup_dir/mysql_backup.sql" 2>/dev/null || true
            docker-compose -f docker-compose.integrated.yml exec -T postgresql pg_dump -U jobfirst jobfirst_advanced > "$backup_dir/postgresql_backup.sql" 2>/dev/null || true
            docker-compose -f docker-compose.integrated.yml exec -T neo4j neo4j-admin database dump neo4j > "$backup_dir/neo4j_backup.dump" 2>/dev/null || true
            ;;
    esac
    
    # 备份配置文件
    cp -r configs "$backup_dir/" 2>/dev/null || true
    cp docker-compose*.yml "$backup_dir/" 2>/dev/null || true
    
    echo -e "${GREEN}✅ 数据备份完成: $backup_dir${NC}"
    echo "$backup_dir"
}

# 恢复数据
restore_data() {
    local target_mode=$1
    local backup_dir=$2
    
    if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
        echo -e "${YELLOW}⚠️  没有找到备份目录，跳过数据恢复${NC}"
        return
    fi
    
    echo -e "${YELLOW}🔄 恢复数据到 $target_mode 模式...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # 等待服务启动
    sleep 10
    
    case $target_mode in
        "basic")
            if [ -f "$backup_dir/mysql_backup.sql" ]; then
                docker-compose exec -T mysql mysql -u root -pjobfirst123 jobfirst < "$backup_dir/mysql_backup.sql" 2>/dev/null || true
            fi
            ;;
        "enhanced")
            if [ -f "$backup_dir/mysql_backup.sql" ]; then
                docker-compose -f docker-compose.enhanced.yml exec -T mysql mysql -u root -pjobfirst123 jobfirst < "$backup_dir/mysql_backup.sql" 2>/dev/null || true
            fi
            if [ -f "$backup_dir/postgresql_backup.sql" ]; then
                docker-compose -f docker-compose.enhanced.yml exec -T postgresql psql -U jobfirst jobfirst_advanced < "$backup_dir/postgresql_backup.sql" 2>/dev/null || true
            fi
            ;;
        "integrated")
            if [ -f "$backup_dir/mysql_backup.sql" ]; then
                docker-compose -f docker-compose.integrated.yml exec -T mysql mysql -u root -pjobfirst123 jobfirst < "$backup_dir/mysql_backup.sql" 2>/dev/null || true
            fi
            if [ -f "$backup_dir/postgresql_backup.sql" ]; then
                docker-compose -f docker-compose.integrated.yml exec -T postgresql psql -U jobfirst jobfirst_advanced < "$backup_dir/postgresql_backup.sql" 2>/dev/null || true
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ 数据恢复完成${NC}"
}

# 停止当前模式
stop_current_mode() {
    local current_mode=$1
    
    echo -e "${YELLOW}🛑 停止 $current_mode 模式...${NC}"
    
    cd "$PROJECT_ROOT"
    
    case $current_mode in
        "basic")
            docker-compose down
            ;;
        "enhanced")
            docker-compose -f docker-compose.enhanced.yml down
            ;;
        "integrated")
            docker-compose -f docker-compose.integrated.yml down
            ;;
    esac
    
    echo -e "${GREEN}✅ $current_mode 模式已停止${NC}"
}

# 启动目标模式
start_target_mode() {
    local target_mode=$1
    
    echo -e "${YELLOW}🚀 启动 $target_mode 模式...${NC}"
    
    cd "$PROJECT_ROOT"
    
    case $target_mode in
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
    
    echo -e "${GREEN}✅ $target_mode 模式启动完成${NC}"
}

# 等待服务就绪
wait_for_services() {
    local target_mode=$1
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

# 验证切换结果
verify_switch() {
    local target_mode=$1
    echo -e "${YELLOW}🔍 验证切换结果...${NC}"
    
    # 检查服务状态
    cd "$PROJECT_ROOT"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep jobfirst || true
    
    # 检查网关健康状态
    local health_response=$(curl -s http://localhost:8080/health 2>/dev/null || echo "{}")
    if echo "$health_response" | grep -q "healthy"; then
        echo -e "${GREEN}✅ 网关健康检查通过${NC}"
    else
        echo -e "${YELLOW}⚠️  网关健康检查异常${NC}"
    fi
    
    # 检查服务数量
    local service_count=$(docker ps --filter "name=jobfirst-" --format "{{.Names}}" | wc -l)
    local expected_count=0
    
    case $target_mode in
        "basic") expected_count=9 ;;
        "enhanced") expected_count=13 ;;
        "integrated") expected_count=20 ;;
    esac
    
    if [ "$service_count" -eq "$expected_count" ]; then
        echo -e "${GREEN}✅ 服务数量正确: $service_count${NC}"
    else
        echo -e "${YELLOW}⚠️  服务数量异常: 期望 $expected_count, 实际 $service_count${NC}"
    fi
}

# 运行测试
run_tests() {
    local target_mode=$1
    echo -e "${YELLOW}🧪 运行功能测试...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # 等待服务完全启动
    sleep 10
    
    # 运行基础测试
    if [ -f "test_auth_cors.js" ]; then
        echo "运行认证和CORS测试..."
        node test_auth_cors.js || echo -e "${YELLOW}⚠️  测试部分失败，但服务已启动${NC}"
    fi
    
    echo -e "${GREEN}✅ 测试完成${NC}"
}

# 显示切换结果
show_switch_result() {
    local source_mode=$1
    local target_mode=$2
    local backup_dir=$3
    
    echo ""
    echo -e "${GREEN}🎉 模式切换完成！${NC}"
    echo ""
    echo -e "${BLUE}📊 切换信息:${NC}"
    echo "   从: $source_mode 模式"
    echo "   到: $target_mode 模式"
    if [ -n "$backup_dir" ]; then
        echo "   备份: $backup_dir"
    fi
    echo ""
    echo -e "${BLUE}🔗 访问地址:${NC}"
    echo "   🌐 网关地址: http://localhost:8080"
    echo "   📋 Consul UI: http://localhost:8202"
    echo "   🗄️  MySQL: localhost:8200"
    echo "   🔴 Redis: localhost:8201"
    
    case $target_mode in
        "enhanced"|"integrated")
            echo "   🐘 PostgreSQL: localhost:8203"
            echo "   🕸️  Neo4j: http://localhost:8204"
            ;;
    esac
    
    case $target_mode in
        "integrated")
            echo "   📈 Prometheus: http://localhost:9090"
            echo "   📊 Grafana: http://localhost:3000"
            echo "   🔍 Jaeger: http://localhost:16686"
            ;;
    esac
    echo ""
}

# 主函数
main() {
    # 解析参数
    local source_mode=""
    local target_mode=""
    local force=false
    local backup=false
    local restore=false
    local test=false
    local backup_dir=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            basic|enhanced|integrated)
                if [ -z "$source_mode" ]; then
                    source_mode="$1"
                elif [ -z "$target_mode" ]; then
                    target_mode="$1"
                else
                    echo -e "${RED}❌ 参数过多${NC}"
                    show_help
                    exit 1
                fi
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
            -b|--backup)
                backup=true
                shift
                ;;
            -r|--restore)
                restore=true
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
    
    # 验证参数
    if [ -z "$source_mode" ] || [ -z "$target_mode" ]; then
        echo -e "${RED}❌ 需要指定源模式和目标模式${NC}"
        show_help
        exit 1
    fi
    
    if [ "$source_mode" = "$target_mode" ]; then
        echo -e "${YELLOW}⚠️  源模式和目标模式相同，无需切换${NC}"
        exit 0
    fi
    
    # 验证模式
    if [[ ! " ${MODES[@]} " =~ " ${source_mode} " ]] || [[ ! " ${MODES[@]} " =~ " ${target_mode} " ]]; then
        echo -e "${RED}❌ 无效的模式${NC}"
        echo "可用模式: ${MODES[*]}"
        exit 1
    fi
    
    # 检查当前运行的模式
    local current_mode=$(get_current_mode)
    if [ "$current_mode" != "$source_mode" ] && [ "$current_mode" != "none" ]; then
        echo -e "${YELLOW}⚠️  当前运行的是 $current_mode 模式，不是 $source_mode 模式${NC}"
        if [ "$force" != true ]; then
            read -p "是否继续切换? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    fi
    
    # 显示切换信息
    echo -e "${CYAN}🔄 JobFirst 模式切换${NC}"
    echo ""
    show_mode_info "$source_mode" "源"
    show_mode_info "$target_mode" "目标"
    
    # 确认操作
    if [ "$force" != true ]; then
        echo -e "${YELLOW}⚠️  此操作将停止当前服务并启动新服务${NC}"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "操作已取消"
            exit 0
        fi
    fi
    
    # 执行切换流程
    if [ "$backup" = true ] && [ "$current_mode" != "none" ]; then
        backup_dir=$(backup_data "$current_mode")
    fi
    
    if [ "$current_mode" != "none" ]; then
        stop_current_mode "$current_mode"
    fi
    
    start_target_mode "$target_mode"
    wait_for_services "$target_mode"
    
    if [ "$restore" = true ] && [ -n "$backup_dir" ]; then
        restore_data "$target_mode" "$backup_dir"
    fi
    
    verify_switch "$target_mode"
    
    if [ "$test" = true ]; then
        run_tests "$target_mode"
    fi
    
    show_switch_result "$source_mode" "$target_mode" "$backup_dir"
}

# 运行主函数
main "$@"
