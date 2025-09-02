#!/bin/bash

# JobFirst 前端+数据库联通测试脚本
# 测试基础模式中前端、网关、数据库之间的联通性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 测试配置
GATEWAY_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"
CONSUL_URL="http://localhost:8202"
MYSQL_HOST="localhost"
MYSQL_PORT="8200"
REDIS_HOST="localhost"
REDIS_PORT="8201"

echo -e "${CYAN}🚀 JobFirst 前端+数据库联通测试${NC}"
echo "=================================="
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}🔍 测试: $test_name${NC}"
    
    if eval "$test_command" 2>/dev/null; then
        echo -e "${GREEN}✅ 通过: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ 失败: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# 1. 容器状态测试
echo -e "${YELLOW}📊 1. 容器状态检查${NC}"
echo "-------------------"

run_test "检查所有容器运行状态" \
    "docker ps --filter 'name=jobfirst-' --format '{{.Names}}: {{.Status}}' | grep -q 'Up'" \
    "所有JobFirst容器应该处于运行状态"

run_test "检查容器数量" \
    "[ \$(docker ps --filter 'name=jobfirst-' --format '{{.Names}}' | wc -l) -ge 5 ]" \
    "应该有至少5个JobFirst容器运行"

# 2. 网关服务测试
echo -e "${YELLOW}🌐 2. 网关服务测试${NC}"
echo "-------------------"

run_test "网关健康检查" \
    "curl -s $GATEWAY_URL/health | grep -q 'healthy'" \
    "网关健康检查应该返回healthy状态"

run_test "网关信息端点" \
    "curl -s $GATEWAY_URL/info | grep -q 'jobfirst-gateway'" \
    "网关信息端点应该返回服务信息"

run_test "网关指标端点" \
    "curl -s $GATEWAY_URL/metrics | grep -q 'gateway'" \
    "网关指标端点应该返回监控数据"

# 3. 前端服务测试
echo -e "${YELLOW}🎨 3. 前端服务测试${NC}"
echo "-------------------"

run_test "前端服务可访问" \
    "curl -s -I $FRONTEND_URL | grep -q '200 OK'" \
    "前端服务应该返回200状态码"

run_test "前端页面内容" \
    "curl -s $FRONTEND_URL | grep -q 'JobFirst\|jobfirst'" \
    "前端页面应该包含JobFirst相关内容"

# 4. 数据库连接测试
echo -e "${YELLOW}🗄️ 4. 数据库连接测试${NC}"
echo "-------------------"

run_test "MySQL容器运行状态" \
    "docker ps --filter 'name=jobfirst-mysql' --format '{{.Status}}' | grep -q 'Up'" \
    "MySQL容器应该处于运行状态"

run_test "MySQL端口监听" \
    "netstat -an | grep -q ':$MYSQL_PORT.*LISTEN'" \
    "MySQL端口应该处于监听状态"

run_test "MySQL连接测试" \
    "docker exec jobfirst-mysql mysql -u root -pjobfirst123 -e 'SELECT 1;' > /dev/null 2>&1" \
    "MySQL数据库应该可以正常连接"

run_test "Redis容器运行状态" \
    "docker ps --filter 'name=jobfirst-redis' --format '{{.Status}}' | grep -q 'Up'" \
    "Redis容器应该处于运行状态"

run_test "Redis端口监听" \
    "netstat -an | grep -q ':$REDIS_PORT.*LISTEN'" \
    "Redis端口应该处于监听状态"

run_test "Redis连接测试" \
    "docker exec jobfirst-redis redis-cli ping | grep -q 'PONG'" \
    "Redis数据库应该可以正常连接"

# 5. Consul服务发现测试
echo -e "${YELLOW}📋 5. Consul服务发现测试${NC}"
echo "-------------------"

run_test "Consul容器运行状态" \
    "docker ps --filter 'name=jobfirst-consul' --format '{{.Status}}' | grep -q 'Up'" \
    "Consul容器应该处于运行状态"

run_test "Consul UI可访问" \
    "curl -s -I $CONSUL_URL | grep -q '200 OK'" \
    "Consul UI应该可以访问"

run_test "Consul API可访问" \
    "curl -s $CONSUL_URL/v1/status/leader | grep -q '.*'" \
    "Consul API应该可以访问"

# 6. 服务间通信测试
echo -e "${YELLOW}🔗 6. 服务间通信测试${NC}"
echo "-------------------"

run_test "网关到MySQL连接" \
    "docker exec jobfirst-gateway ping -c 1 jobfirst-mysql > /dev/null 2>&1" \
    "网关应该能够ping通MySQL服务"

run_test "网关到Redis连接" \
    "docker exec jobfirst-gateway ping -c 1 jobfirst-redis > /dev/null 2>&1" \
    "网关应该能够ping通Redis服务"

run_test "网关到Consul连接" \
    "docker exec jobfirst-gateway ping -c 1 jobfirst-consul > /dev/null 2>&1" \
    "网关应该能够ping通Consul服务"

# 7. API路由测试
echo -e "${YELLOW}🛣️ 7. API路由测试${NC}"
echo "-------------------"

run_test "公开API路由" \
    "curl -s $GATEWAY_URL/api/auth/login | grep -q '.*'" \
    "公开API路由应该可以访问"

run_test "认证API路由(无token)" \
    "curl -s -w '%{http_code}' $GATEWAY_URL/api/v1/user/profile | grep -q '401\|404'" \
    "认证API路由应该返回401或404"

run_test "CORS预检请求" \
    "curl -s -X OPTIONS $GATEWAY_URL/api/v1/user/profile -H 'Origin: http://localhost:3000' -w '%{http_code}' | grep -q '204'" \
    "CORS预检请求应该返回204"

# 8. 数据库数据测试
echo -e "${YELLOW}📊 8. 数据库数据测试${NC}"
echo "-------------------"

run_test "MySQL数据库存在" \
    "docker exec jobfirst-mysql mysql -u root -pjobfirst123 -e 'SHOW DATABASES;' | grep -q 'jobfirst'" \
    "jobfirst数据库应该存在"

run_test "MySQL表结构" \
    "docker exec jobfirst-mysql mysql -u root -pjobfirst123 -e 'USE jobfirst; SHOW TABLES;' | grep -q '.*'" \
    "MySQL应该有表结构"

run_test "Redis键空间" \
    "docker exec jobfirst-redis redis-cli info keyspace | grep -q '.*'" \
    "Redis键空间信息应该可获取"

# 9. 网络连通性测试
echo -e "${YELLOW}🌐 9. 网络连通性测试${NC}"
echo "-------------------"

run_test "Docker网络存在" \
    "docker network ls | grep -q 'jobfirst'" \
    "JobFirst Docker网络应该存在"

run_test "容器在同一网络" \
    "docker network inspect jobfirst_jobfirst-network | grep -q 'jobfirst-gateway'" \
    "所有容器应该在同一个网络中"

# 10. 性能测试
echo -e "${YELLOW}⚡ 10. 性能测试${NC}"
echo "-------------------"

run_test "网关响应时间" \
    "timeout 5 curl -s $GATEWAY_URL/health > /dev/null" \
    "网关响应时间应该在5秒内"

run_test "前端响应时间" \
    "timeout 10 curl -s $FRONTEND_URL > /dev/null" \
    "前端响应时间应该在10秒内"

# 测试结果统计
echo -e "${CYAN}📊 测试结果统计${NC}"
echo "=================="
echo -e "总测试数: ${TOTAL_TESTS}"
echo -e "通过测试: ${GREEN}${PASSED_TESTS}${NC}"
echo -e "失败测试: ${RED}${FAILED_TESTS}${NC}"
echo -e "成功率: ${GREEN}$((PASSED_TESTS * 100 / TOTAL_TESTS))%${NC}"
echo ""

# 详细状态报告
echo -e "${CYAN}📋 详细状态报告${NC}"
echo "=================="

echo -e "${BLUE}容器状态:${NC}"
docker ps --filter "name=jobfirst-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${BLUE}服务访问地址:${NC}"
echo "   🌐 前端地址: $FRONTEND_URL"
echo "   🔗 网关地址: $GATEWAY_URL"
echo "   📋 Consul UI: $CONSUL_URL"
echo "   🗄️  MySQL: $MYSQL_HOST:$MYSQL_PORT"
echo "   🔴 Redis: $REDIS_HOST:$REDIS_PORT"

echo ""
echo -e "${BLUE}健康检查:${NC}"
echo "   网关健康: $(curl -s $GATEWAY_URL/health | jq -r '.status' 2>/dev/null || echo 'unknown')"
echo "   MySQL连接: $(docker exec jobfirst-mysql mysql -u root -pjobfirst123 -e 'SELECT 1;' > /dev/null 2>&1 && echo 'OK' || echo 'FAIL')"
echo "   Redis连接: $(docker exec jobfirst-redis redis-cli ping > /dev/null 2>&1 && echo 'OK' || echo 'FAIL')"

echo ""
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！前端+数据库联通性正常。${NC}"
else
    echo -e "${YELLOW}⚠️  部分测试失败，请检查相关服务。${NC}"
fi

echo ""
echo -e "${CYAN}💡 建议:${NC}"
echo "   - 如果前端无法访问，检查端口3000是否被占用"
echo "   - 如果数据库连接失败，检查端口8200和8201"
echo "   - 如果网关异常，查看网关日志: docker logs jobfirst-gateway"
echo "   - 如果服务发现异常，检查Consul服务: docker logs jobfirst-consul"
