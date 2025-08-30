#!/bin/bash

echo "🛑 停止JobFirst所有微服务"
echo "========================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查PID文件
if [ ! -f ".service_pids" ]; then
    echo -e "${YELLOW}⚠️  未找到服务PID文件，可能服务未启动${NC}"
    exit 1
fi

echo "🔍 读取服务PID..."
pids=$(cat .service_pids)

echo "🛑 停止微服务..."
for pid in $pids; do
    if ps -p $pid > /dev/null 2>&1; then
        echo "停止PID: $pid"
        kill $pid 2>/dev/null
        sleep 1
        if ps -p $pid > /dev/null 2>&1; then
            echo "强制停止PID: $pid"
            kill -9 $pid 2>/dev/null
        fi
    else
        echo "PID $pid 已停止"
    fi
done

# 删除PID文件
rm -f .service_pids

echo ""
echo -e "${GREEN}✅ 所有微服务已停止${NC}"

echo ""
echo "💡 提示:"
echo "   - 基础设施服务(Docker)仍在运行"
echo "   - 如需停止基础设施: docker-compose -f docker-compose.dev.yml down"
echo "   - 如需停止网关: 手动停止网关进程"
