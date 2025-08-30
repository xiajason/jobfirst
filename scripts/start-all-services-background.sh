#!/bin/bash

echo "🚀 后台启动JobFirst所有微服务"
echo "============================"

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

# 创建日志目录
mkdir -p logs

# 启动微服务
echo ""
echo "🚀 后台启动微服务..."
echo "=================="

# 用户服务
echo -e "${BLUE}📡 启动用户服务 (端口: 8001)...${NC}"
cd backend/user
nohup go run main.go > ../../logs/user.log 2>&1 &
USER_PID=$!
echo "用户服务PID: $USER_PID"
cd ../..

# 简历服务
echo -e "${BLUE}📄 启动简历服务 (端口: 8002)...${NC}"
cd backend/resume
nohup go run main.go > ../../logs/resume.log 2>&1 &
RESUME_PID=$!
echo "简历服务PID: $RESUME_PID"
cd ../..

# 积分服务
echo -e "${BLUE}🎯 启动积分服务 (端口: 8003)...${NC}"
cd backend/points
nohup go run main.go > ../../logs/points.log 2>&1 &
POINTS_PID=$!
echo "积分服务PID: $POINTS_PID"
cd ../..

# 统计服务
echo -e "${BLUE}📊 启动统计服务 (端口: 8004)...${NC}"
cd backend/statistics
nohup go run main.go > ../../logs/statistics.log 2>&1 &
STATISTICS_PID=$!
echo "统计服务PID: $STATISTICS_PID"
cd ../..

# 存储服务
echo -e "${BLUE}💾 启动存储服务 (端口: 8005)...${NC}"
cd backend/storage
nohup go run main.go > ../../logs/storage.log 2>&1 &
STORAGE_PID=$!
echo "存储服务PID: $STORAGE_PID"
cd ../..

# 保存PID到文件
echo "$USER_PID $RESUME_PID $POINTS_PID $STATISTICS_PID $STORAGE_PID" > .service_pids

# 等待服务启动
echo ""
echo "⏳ 等待服务启动..."
sleep 8

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
echo "💡 管理命令:"
echo "   - 查看服务状态: ./scripts/check-services.sh"
echo "   - 查看日志: tail -f logs/*.log"
echo "   - 停止所有服务: ./scripts/stop-all-services.sh"
echo "   - 重启服务: ./scripts/restart-services.sh"

echo ""
echo -e "${GREEN}✅ 所有微服务已在后台启动完成！${NC}"
echo "现在您可以继续使用终端进行其他操作。"
