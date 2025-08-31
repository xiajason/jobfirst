#!/bin/bash

# JobFirst 测试环境访问验证脚本
echo "=== JobFirst 测试环境访问验证 ==="
echo "时间: $(date)"
echo "测试环境: 101.33.251.158"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    local url=$1
    local description=$2
    local expected_status=${3:-200}
    
    echo -n "测试 $description... "
    
    # 使用curl测试端点
    response=$(curl -s -w "%{http_code}" -o /tmp/response_body "$url" 2>/dev/null)
    http_code="${response: -3}"
    response_body=$(cat /tmp/response_body 2>/dev/null)
    
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ 成功 (HTTP $http_code)${NC}"
        if [ ! -z "$response_body" ]; then
            echo "   响应: $response_body"
        fi
        return 0
    else
        echo -e "${RED}❌ 失败 (HTTP $http_code)${NC}"
        if [ ! -z "$response_body" ]; then
            echo "   错误: $response_body"
        fi
        return 1
    fi
}

# 端口连通性测试
test_port() {
    local port=$1
    local service=$2
    
    echo -n "测试 $service 端口 $port... "
    if nc -z -w5 101.33.251.158 $port 2>/dev/null; then
        echo -e "${GREEN}✅ 可访问${NC}"
        return 0
    else
        echo -e "${RED}❌ 不可访问${NC}"
        return 1
    fi
}

# 开始测试
echo -e "${BLUE}1. 端口连通性测试${NC}"
echo "================================"

test_port 8000 "API网关"
test_port 8210 "共享基础设施"
test_port 3306 "MySQL数据库"
test_port 6379 "Redis缓存"

echo ""
echo -e "${BLUE}2. HTTP服务测试${NC}"
echo "================================"

# 测试API网关
test_endpoint "http://101.33.251.158:8000/health" "API网关健康检查"
test_endpoint "http://101.33.251.158:8000/" "API网关根路径"
test_endpoint "http://101.33.251.158:8000/api/v1/status" "API网关状态"

# 测试共享基础设施
test_endpoint "http://101.33.251.158:8210/health" "共享基础设施健康检查"
test_endpoint "http://101.33.251.158:8210/" "共享基础设施根路径"

echo ""
echo -e "${BLUE}3. 数据库连接测试${NC}"
echo "================================"

# 测试MySQL连接（需要安装mysql客户端）
if command -v mysql &> /dev/null; then
    echo -n "测试MySQL连接... "
    if mysql -h 101.33.251.158 -P 3306 -u root -p'jobfirst123' -e "SELECT 1;" 2>/dev/null; then
        echo -e "${GREEN}✅ 连接成功${NC}"
    else
        echo -e "${RED}❌ 连接失败${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  MySQL客户端未安装，跳过数据库连接测试${NC}"
fi

# 测试Redis连接（需要安装redis-cli）
if command -v redis-cli &> /dev/null; then
    echo -n "测试Redis连接... "
    if redis-cli -h 101.33.251.158 -p 6379 ping 2>/dev/null | grep -q "PONG"; then
        echo -e "${GREEN}✅ 连接成功${NC}"
    else
        echo -e "${RED}❌ 连接失败${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Redis客户端未安装，跳过Redis连接测试${NC}"
fi

echo ""
echo -e "${BLUE}4. 服务状态总结${NC}"
echo "================================"

# 统计测试结果
total_tests=0
passed_tests=0

# 重新运行关键测试并统计
echo "关键服务状态:"
if test_endpoint "http://101.33.251.158:8000/health" "API网关" >/dev/null; then
    echo -e "  ${GREEN}✅ API网关: 运行中${NC}"
    ((passed_tests++))
else
    echo -e "  ${RED}❌ API网关: 未运行${NC}"
fi
((total_tests++))

if test_endpoint "http://101.33.251.158:8210/health" "共享基础设施" >/dev/null; then
    echo -e "  ${GREEN}✅ 共享基础设施: 运行中${NC}"
    ((passed_tests++))
else
    echo -e "  ${RED}❌ 共享基础设施: 未运行${NC}"
fi
((total_tests++))

if test_port 3306 "MySQL" >/dev/null; then
    echo -e "  ${GREEN}✅ MySQL数据库: 运行中${NC}"
    ((passed_tests++))
else
    echo -e "  ${RED}❌ MySQL数据库: 未运行${NC}"
fi
((total_tests++))

if test_port 6379 "Redis" >/dev/null; then
    echo -e "  ${GREEN}✅ Redis缓存: 运行中${NC}"
    ((passed_tests++))
else
    echo -e "  ${RED}❌ Redis缓存: 未运行${NC}"
fi
((total_tests++))

echo ""
echo -e "${BLUE}5. 测试结果${NC}"
echo "================================"

success_rate=$((passed_tests * 100 / total_tests))
echo "测试通过率: $passed_tests/$total_tests ($success_rate%)"

if [ $success_rate -ge 75 ]; then
    echo -e "${GREEN}🎉 测试环境基本可用，可以开始开发测试工作！${NC}"
    echo ""
    echo -e "${BLUE}访问地址:${NC}"
    echo "  API网关: http://101.33.251.158:8000"
    echo "  共享基础设施: http://101.33.251.158:8210"
    echo "  健康检查: http://101.33.251.158:8000/health"
    echo ""
    echo -e "${BLUE}下一步建议:${NC}"
    echo "  1. 完善健康检查端点"
    echo "  2. 配置用户认证系统"
    echo "  3. 设置监控和日志"
    echo "  4. 开始功能开发"
elif [ $success_rate -ge 50 ]; then
    echo -e "${YELLOW}⚠️ 测试环境部分可用，需要进一步优化${NC}"
    echo ""
    echo -e "${BLUE}需要解决的问题:${NC}"
    echo "  1. 检查服务启动状态"
    echo "  2. 验证配置文件"
    echo "  3. 查看服务日志"
    echo "  4. 完善健康检查"
else
    echo -e "${RED}❌ 测试环境不可用，需要重新部署${NC}"
    echo ""
    echo -e "${BLUE}建议操作:${NC}"
    echo "  1. 检查服务器状态"
    echo "  2. 重新部署服务"
    echo "  3. 验证网络配置"
    echo "  4. 查看错误日志"
fi

echo ""
echo "=== 测试完成 ==="
