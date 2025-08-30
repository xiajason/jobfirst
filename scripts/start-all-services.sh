#!/bin/bash

echo "🚀 启动JobFirst所有微服务"
echo "========================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查基础设施服务是否运行
echo "🔍 检查基础设施服务..."
if ! docker ps | grep -q "jobfirst-mysql-dev"; then
    echo -e "${RED}❌ MySQL服务未运行，请先启动基础设施服务${NC}"
    exit 1
fi

if ! docker ps | grep -q "jobfirst-redis-dev"; then
    echo -e "${RED}❌ Redis服务未运行，请先启动基础设施服务${NC}"
    exit 1
fi

if ! docker ps | grep -q "jobfirst-consul-dev"; then
    echo -e "${RED}❌ Consul服务未运行，请先启动基础设施服务${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 基础设施服务运行正常${NC}"

# 检查网关是否运行
echo "🔍 检查API网关..."
if ! curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${RED}❌ API网关未运行，请先启动网关服务${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API网关运行正常${NC}"

# 启动微服务
echo ""
echo "🚀 启动微服务..."
echo "================"

# 用户服务
echo -e "${BLUE}📡 启动用户服务 (端口: 8001)...${NC}"
cd backend/user
go run main.go &
USER_PID=$!
echo "用户服务PID: $USER_PID"
cd ../..

# 简历服务
echo -e "${BLUE}📄 启动简历服务 (端口: 8002)...${NC}"
cd backend/resume
go run main.go &
RESUME_PID=$!
echo "简历服务PID: $RESUME_PID"
cd ../..

# 积分服务
echo -e "${BLUE}🎯 启动积分服务 (端口: 8003)...${NC}"
cd backend/points
go run main.go &
POINTS_PID=$!
echo "积分服务PID: $POINTS_PID"
cd ../..

# 统计服务
echo -e "${BLUE}📊 启动统计服务 (端口: 8004)...${NC}"
cd backend/statistics
go run main.go &
STATISTICS_PID=$!
echo "统计服务PID: $STATISTICS_PID"
cd ../..

# 存储服务
echo -e "${BLUE}💾 启动存储服务 (端口: 8005)...${NC}"
cd backend/storage
go run main.go &
STORAGE_PID=$!
echo "存储服务PID: $STORAGE_PID"
cd ../..

# 等待服务启动
echo ""
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
echo ""
echo "🔍 检查服务状态..."
echo "=================="

check_service() {
    local service_name=$1
    local port=$2
    local url="http://localhost:$port/health"
    
    if curl -s "$url" > /dev/null; then
        echo -e "${GREEN}✅ $service_name (端口: $port) - 运行正常${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name (端口: $port) - 启动失败${NC}"
        return 1
    fi
}

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

echo ""
echo "💡 提示:"
echo "   - 使用 Ctrl+C 停止所有服务"
echo "   - 查看日志: tail -f backend/*/logs/*.log"
echo "   - 重启单个服务: cd backend/[service] && go run main.go"

# 保存PID到文件
echo "$USER_PID $RESUME_PID $POINTS_PID $STATISTICS_PID $STORAGE_PID" > .service_pids

# 等待中断信号
trap 'echo ""; echo "🛑 正在停止所有服务..."; kill $USER_PID $RESUME_PID $POINTS_PID $STATISTICS_PID $STORAGE_PID 2>/dev/null; rm -f .service_pids; echo "✅ 所有服务已停止"; exit 0' INT TERM

# 保持脚本运行
echo ""
echo "🔄 服务运行中... (按 Ctrl+C 停止)"
while true; do
    sleep 1
done
