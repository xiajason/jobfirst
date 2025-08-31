#!/bin/bash

# JobFirst数据库健康检查脚本
# 用于监控所有数据库服务的状态

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

# 检查MySQL健康状态
check_mysql() {
    log_info "检查MySQL健康状态..."
    
    if docker ps | grep -q jobfirst-mysql; then
        if docker exec jobfirst-mysql mysqladmin ping -u jobfirst -pjobfirst123 > /dev/null 2>&1; then
            # 获取MySQL状态信息
            local connections=$(docker exec jobfirst-mysql mysql -u jobfirst -pjobfirst123 -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -n 1 | awk '{print $2}')
            local uptime=$(docker exec jobfirst-mysql mysql -u jobfirst -pjobfirst123 -e "SHOW STATUS LIKE 'Uptime';" 2>/dev/null | tail -n 1 | awk '{print $2}')
            
            log_success "MySQL: 运行正常"
            echo "  连接数: $connections"
            echo "  运行时间: $uptime 秒"
            return 0
        else
            log_error "MySQL: 连接失败"
            return 1
        fi
    else
        log_error "MySQL: 容器未运行"
        return 1
    fi
}

# 检查Redis健康状态
check_redis() {
    log_info "检查Redis健康状态..."
    
    if docker ps | grep -q jobfirst-redis; then
        if docker exec jobfirst-redis redis-cli ping > /dev/null 2>&1; then
            # 获取Redis状态信息
            local info=$(docker exec jobfirst-redis redis-cli info 2>/dev/null)
            local connected_clients=$(echo "$info" | grep "connected_clients:" | cut -d: -f2)
            local used_memory=$(echo "$info" | grep "used_memory_human:" | cut -d: -f2)
            local keys=$(docker exec jobfirst-redis redis-cli dbsize 2>/dev/null)
            
            log_success "Redis: 运行正常"
            echo "  连接数: $connected_clients"
            echo "  内存使用: $used_memory"
            echo "  键数量: $keys"
            return 0
        else
            log_error "Redis: 连接失败"
            return 1
        fi
    else
        log_error "Redis: 容器未运行"
        return 1
    fi
}

# 检查PostgreSQL健康状态
check_postgresql() {
    log_info "检查PostgreSQL健康状态..."
    
    if docker ps | grep -q jobfirst-postgresql; then
        if docker exec jobfirst-postgresql pg_isready -U jobfirst > /dev/null 2>&1; then
            # 获取PostgreSQL状态信息
            local connections=$(docker exec jobfirst-postgresql psql -U jobfirst -d jobfirst_advanced -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tail -n 1 | tr -d ' ')
            local databases=$(docker exec jobfirst-postgresql psql -U jobfirst -d jobfirst_advanced -c "SELECT count(*) FROM pg_database;" 2>/dev/null | tail -n 1 | tr -d ' ')
            
            log_success "PostgreSQL: 运行正常"
            echo "  连接数: $connections"
            echo "  数据库数: $databases"
            return 0
        else
            log_error "PostgreSQL: 连接失败"
            return 1
        fi
    else
        log_error "PostgreSQL: 容器未运行"
        return 1
    fi
}

# 检查Neo4j健康状态
check_neo4j() {
    log_info "检查Neo4j健康状态..."
    
    if docker ps | grep -q jobfirst-neo4j; then
        if curl -s -u jobfirst:jobfirst123 http://localhost:8204/browser/ > /dev/null 2>&1; then
            # 获取Neo4j状态信息
            local node_count=$(curl -s -u jobfirst:jobfirst123 -H "Content-Type: application/json" \
                -d '{"statements":[{"statement":"MATCH (n) RETURN count(n) as count"}]}' \
                http://localhost:8204/db/neo4j/tx/commit 2>/dev/null | grep -o '"count":[0-9]*' | cut -d: -f2)
            
            log_success "Neo4j: 运行正常"
            echo "  节点数量: ${node_count:-0}"
            return 0
        else
            log_error "Neo4j: 连接失败"
            return 1
        fi
    else
        log_error "Neo4j: 容器未运行"
        return 1
    fi
}

# 检查端口占用
check_ports() {
    log_info "检查端口占用情况..."
    
    local ports=("8200:MySQL" "8201:Redis" "8203:PostgreSQL" "8204:Neo4j-HTTP" "8205:Neo4j-Bolt")
    local all_ok=true
    
    for port_info in "${ports[@]}"; do
        local port=$(echo $port_info | cut -d: -f1)
        local service=$(echo $port_info | cut -d: -f2)
        
        if lsof -i :$port > /dev/null 2>&1; then
            log_success "$service (端口$port): 已占用"
        else
            log_warning "$service (端口$port): 未占用"
            all_ok=false
        fi
    done
    
    return $([ "$all_ok" = true ] && echo 0 || echo 1)
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    local usage=$(df -h . | tail -n 1)
    local percentage=$(echo $usage | awk '{print $5}' | sed 's/%//')
    
    if [ $percentage -lt 80 ]; then
        log_success "磁盘空间充足: $percentage%"
        echo "  使用情况: $usage"
    else
        log_warning "磁盘空间不足: $percentage%"
        echo "  使用情况: $usage"
        return 1
    fi
    
    return 0
}

# 检查Docker资源使用
check_docker_resources() {
    log_info "检查Docker资源使用..."
    
    local stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}")
    echo "$stats" | while IFS=$'\t' read -r container cpu mem_usage mem_perc; do
        if [[ $container == *"jobfirst"* ]]; then
            echo "  $container: CPU $cpu, 内存 $mem_usage ($mem_perc)"
        fi
    done
}

# 生成健康报告
generate_health_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="backup/health_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "JobFirst数据库健康检查报告" > $report_file
    echo "生成时间: $timestamp" >> $report_file
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $report_file
    echo "" >> $report_file
    
    # 重定向输出到文件
    {
        check_mysql
        echo ""
        check_redis
        echo ""
        check_postgresql
        echo ""
        check_neo4j
        echo ""
        check_ports
        echo ""
        check_disk_space
        echo ""
        check_docker_resources
    } >> $report_file 2>&1
    
    log_info "健康检查报告已保存到: $report_file"
}

# 主函数
main() {
    echo "JobFirst数据库健康检查"
    echo "版本: 1.0"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local exit_code=0
    
    # 检查各个服务
    check_mysql || exit_code=1
    echo ""
    
    check_redis || exit_code=1
    echo ""
    
    check_postgresql || exit_code=1
    echo ""
    
    check_neo4j || exit_code=1
    echo ""
    
    check_ports || exit_code=1
    echo ""
    
    check_disk_space || exit_code=1
    echo ""
    
    check_docker_resources
    echo ""
    
    # 生成报告
    generate_health_report
    
    # 总结
    if [ $exit_code -eq 0 ]; then
        log_success "所有数据库服务运行正常！"
    else
        log_warning "部分服务存在问题，请检查上述错误信息"
    fi
    
    exit $exit_code
}

# 执行主函数
main "$@"
