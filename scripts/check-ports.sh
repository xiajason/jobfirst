#!/bin/bash

echo "🔍 JobFirst 端口占用检查"
echo "========================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查端口函数
check_port() {
    local port=$1
    local service=$2
    local description=$3
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}⚠️  端口 $port ($service) 已被占用${NC}"
        echo -e "${BLUE}   描述: $description${NC}"
        echo -e "${YELLOW}   占用进程:${NC}"
        lsof -i :$port | grep LISTEN
        echo ""
    else
        echo -e "${GREEN}✅ 端口 $port ($service) 可用${NC}"
        echo -e "${BLUE}   描述: $description${NC}"
        echo ""
    fi
}

echo "📊 检查JobFirst核心服务端口 (8000-8099)..."
echo "----------------------------------------"

check_port 8000 "API网关" "统一入口"
check_port 8001 "用户服务" "用户管理"
check_port 8002 "简历服务" "简历管理"
check_port 8003 "积分服务" "积分系统"
check_port 8004 "统计服务" "数据统计"
check_port 8005 "存储服务" "文件存储"
check_port 8006 "前端Web" "Next.js应用"
check_port 8007 "管理后台" "管理界面"

echo "📊 检查基础设施服务端口 (8200-8299)..."
echo "----------------------------------------"

check_port 8200 "MySQL数据库" "主数据库"
check_port 8201 "Redis缓存" "缓存服务"
check_port 8202 "Consul服务发现" "服务注册发现"
check_port 8203 "Neo4j图数据库" "图数据库HTTP"
check_port 8204 "Neo4j Bolt" "图数据库Bolt"
check_port 8205 "PostgreSQL" "关系数据库"

echo "📊 检查监控运维服务端口 (8300-8399)..."
echo "----------------------------------------"

check_port 8300 "Prometheus" "监控指标"
check_port 8301 "Grafana" "监控面板"
check_port 8302 "Kibana" "日志分析"
check_port 8303 "Elasticsearch" "搜索引擎"

echo "📊 检查第三方集成端口 (8400-8499)..."
echo "----------------------------------------"

check_port 8400 "Kong API网关" "API网关"
check_port 8401 "Kong Admin" "网关管理"
check_port 8402 "Kong Status" "网关状态"

echo "📊 检查当前Docker容器端口..."
echo "----------------------------------------"

# 检查Docker容器端口
if command -v docker &> /dev/null; then
    echo "🐳 Docker容器端口映射:"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "(jobfirst|talent|looma|kong|monica|zervi|neo4j)" || echo "   未发现相关容器"
else
    echo "❌ Docker未安装或未运行"
fi

echo ""
echo "📋 端口分配建议:"
echo "=================="

echo "🎯 如果发现端口冲突，建议:"
echo "   1. 停止冲突的服务"
echo "   2. 使用新的端口分配方案"
echo "   3. 更新配置文件"
echo "   4. 重新启动服务"

echo ""
echo "🔧 常用命令:"
echo "   - 停止服务: docker-compose down"
echo "   - 查看端口: lsof -i :端口号"
echo "   - 杀死进程: kill -9 进程ID"
echo "   - 检查Docker: docker ps"

echo ""
echo "📚 更多信息请参考: docs/port-management-strategy.md"
