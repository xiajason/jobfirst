#!/bin/bash

echo "🔍 检查JobFirst服务状态"
echo "======================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_service() {
    local service_name=$1
    local port=$2
    local url="http://localhost:$port/health"
    
    if curl -s "$url" > /dev/null; then
        echo -e "${GREEN}✅ $service_name (端口: $port) - 运行正常${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name (端口: $port) - 未运行${NC}"
        return 1
    fi
}

echo "📊 基础设施服务状态:"
echo "===================="
if docker ps | grep -q "jobfirst-mysql-dev"; then
    echo -e "${GREEN}✅ MySQL (端口: 8200) - 运行正常${NC}"
else
    echo -e "${RED}❌ MySQL (端口: 8200) - 未运行${NC}"
fi

if docker ps | grep -q "jobfirst-redis-dev"; then
    echo -e "${GREEN}✅ Redis (端口: 8201) - 运行正常${NC}"
else
    echo -e "${RED}❌ Redis (端口: 8201) - 未运行${NC}"
fi

if docker ps | grep -q "jobfirst-consul-dev"; then
    echo -e "${GREEN}✅ Consul (端口: 8202) - 运行正常${NC}"
else
    echo -e "${RED}❌ Consul (端口: 8202) - 未运行${NC}"
fi

if docker ps | grep -q "jobfirst-neo4j-dev"; then
    echo -e "${GREEN}✅ Neo4j (端口: 8203) - 运行正常${NC}"
else
    echo -e "${RED}❌ Neo4j (端口: 8203) - 未运行${NC}"
fi

echo ""
echo "📊 微服务状态:"
echo "============="
check_service "API网关" "8000"
check_service "用户服务" "8001"
check_service "简历服务" "8002"
check_service "积分服务" "8003"
check_service "统计服务" "8004"
check_service "存储服务" "8005"

echo ""
echo "📋 服务访问地址:"
echo "================"
echo -e "${GREEN}🌐 API网关: http://localhost:8000${NC}"
echo -e "${GREEN}👤 用户服务: http://localhost:8001${NC}"
echo -e "${GREEN}📄 简历服务: http://localhost:8002${NC}"
echo -e "${GREEN}🎯 积分服务: http://localhost:8003${NC}"
echo -e "${GREEN}📊 统计服务: http://localhost:8004${NC}"
echo -e "${GREEN}💾 存储服务: http://localhost:8005${NC}"
echo ""
echo -e "${GREEN}🔧 Consul管理界面: http://localhost:8202${NC}"
echo -e "${GREEN}🗄️  Neo4j浏览器: http://localhost:8203${NC}"

# 检查PID文件
if [ -f ".service_pids" ]; then
    echo ""
    echo "📋 后台服务PID:"
    echo "=============="
    pids=$(cat .service_pids)
    for pid in $pids; do
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PID $pid - 运行中${NC}"
        else
            echo -e "${RED}❌ PID $pid - 已停止${NC}"
        fi
    done
else
    echo ""
    echo -e "${YELLOW}⚠️  未找到服务PID文件${NC}"
fi
