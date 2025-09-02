#!/bin/bash

# JobFirst 集成模式前端+数据库联通测试脚本
# 测试时间: $(date '+%Y-%m-%d %H:%M:%S')

echo "🚀 JobFirst 集成模式前端+数据库联通测试"
echo "=================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试计数器
total_tests=0
passed_tests=0
failed_tests=0

# 测试函数
test_check() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    total_tests=$((total_tests + 1))
    echo -n "   🔍 $test_name: "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}❌ 失败${NC}"
        failed_tests=$((failed_tests + 1))
    fi
}

# 等待服务启动
wait_for_service() {
    local service_name="$1"
    local port="$2"
    local max_attempts=30
    local attempt=1
    
    echo "⏳ 等待 $service_name 服务启动..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$port" >/dev/null 2>&1; then
            echo "✅ $service_name 服务已启动"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo "❌ $service_name 服务启动超时"
    return 1
}

echo "📋 1. 容器状态检查"
echo "--------------------------------------------------"

# 检查Docker容器状态
test_check "Docker容器运行状态" "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep jobfirst"

echo ""
echo "📋 2. 基础设施服务检查"
echo "--------------------------------------------------"

# MySQL数据库
test_check "MySQL端口监听" "lsof -i :8200 >/dev/null 2>&1"
test_check "MySQL连接测试" "mysql -h localhost -P 8200 -u jobfirst -pjobfirst123 -e 'SELECT 1' >/dev/null 2>&1"

# Redis缓存
test_check "Redis端口监听" "lsof -i :8201 >/dev/null 2>&1"
test_check "Redis连接测试" "redis-cli -h localhost -p 8201 ping >/dev/null 2>&1"

# Consul服务发现
test_check "Consul端口监听" "lsof -i :8202 >/dev/null 2>&1"
test_check "Consul健康检查" "curl -s http://localhost:8202/v1/status/leader >/dev/null 2>&1"

# Neo4j图数据库
test_check "Neo4j HTTP端口监听" "lsof -i :8203 >/dev/null 2>&1"
test_check "Neo4j Bolt端口监听" "lsof -i :8204 >/dev/null 2>&1"

# PostgreSQL数据库
test_check "PostgreSQL端口监听" "lsof -i :8205 >/dev/null 2>&1"

echo ""
echo "📋 3. 监控服务检查"
echo "--------------------------------------------------"

# Prometheus监控
test_check "Prometheus端口监听" "lsof -i :9090 >/dev/null 2>&1"
test_check "Prometheus健康检查" "curl -s http://localhost:9090/-/healthy >/dev/null 2>&1"

# Grafana监控面板
test_check "Grafana端口监听" "lsof -i :3000 >/dev/null 2>&1"
test_check "Grafana健康检查" "curl -s http://localhost:3000/api/health >/dev/null 2>&1"

echo ""
echo "📋 4. 共享基础设施服务检查"
echo "--------------------------------------------------"

# 等待共享基础设施服务启动
if wait_for_service "shared-infrastructure" "8210"; then
    test_check "共享基础设施健康检查" "curl -s http://localhost:8210/health >/dev/null 2>&1"
    test_check "共享基础设施信息" "curl -s http://localhost:8210/info >/dev/null 2>&1"
    test_check "共享基础设施指标" "curl -s http://localhost:8210/metrics >/dev/null 2>&1"
    test_check "数据库状态检查" "curl -s http://localhost:8210/database/status >/dev/null 2>&1"
    test_check "服务注册状态" "curl -s http://localhost:8210/registry/status >/dev/null 2>&1"
    test_check "安全状态检查" "curl -s http://localhost:8210/security/status >/dev/null 2>&1"
    test_check "追踪状态检查" "curl -s http://localhost:8210/tracing/status >/dev/null 2>&1"
    test_check "消息队列状态" "curl -s http://localhost:8210/messaging/status >/dev/null 2>&1"
    test_check "缓存状态检查" "curl -s http://localhost:8210/cache/status >/dev/null 2>&1"
else
    echo "❌ 共享基础设施服务启动失败"
    failed_tests=$((failed_tests + 9))
    total_tests=$((total_tests + 9))
fi

echo ""
echo "📋 5. API网关服务检查"
echo "--------------------------------------------------"

# 等待API网关服务启动
if wait_for_service "gateway" "8000"; then
    test_check "API网关健康检查" "curl -s http://localhost:8000/health >/dev/null 2>&1"
    test_check "API网关信息" "curl -s http://localhost:8000/info >/dev/null 2>&1"
    test_check "API网关指标" "curl -s http://localhost:8000/metrics >/dev/null 2>&1"
else
    echo "❌ API网关服务启动失败"
    failed_tests=$((failed_tests + 3))
    total_tests=$((total_tests + 3))
fi

echo ""
echo "📋 6. 业务服务检查"
echo "--------------------------------------------------"

# 用户服务
test_check "用户服务端口监听" "lsof -i :8001 >/dev/null 2>&1"

# 简历服务
test_check "简历服务端口监听" "lsof -i :8002 >/dev/null 2>&1"

# AI服务
test_check "AI服务端口监听" "lsof -i :8003 >/dev/null 2>&1"

# Web前端
test_check "Web前端端口监听" "lsof -i :3000 >/dev/null 2>&1"

echo ""
echo "📋 7. 网络连通性检查"
echo "--------------------------------------------------"

# 检查容器间网络连通性
test_check "容器网络连通性" "docker network ls | grep jobfirst >/dev/null 2>&1"

# 检查端口监听状态
test_check "端口监听状态" "netstat -tuln | grep -E ':(8200|8201|8202|8203|8204|8205|8000|8001|8002|8003|3000|9090)' >/dev/null 2>&1"

echo ""
echo "📋 8. 数据完整性检查"
echo "--------------------------------------------------"

# MySQL数据检查
test_check "MySQL数据库存在" "mysql -h localhost -P 8200 -u jobfirst -pjobfirst123 -e 'SHOW DATABASES;' | grep jobfirst >/dev/null 2>&1"

# Redis数据检查
test_check "Redis数据库连接" "redis-cli -h localhost -p 8201 ping | grep PONG >/dev/null 2>&1"

# PostgreSQL数据检查
test_check "PostgreSQL数据库存在" "PGPASSWORD=jobfirst123 psql -h localhost -p 8205 -U jobfirst -d jobfirst -c '\l' >/dev/null 2>&1"

echo ""
echo "📋 9. 监控数据检查"
echo "--------------------------------------------------"

# Prometheus指标检查
test_check "Prometheus指标收集" "curl -s http://localhost:9090/api/v1/query?query=up | grep -q 'result' >/dev/null 2>&1"

# Grafana仪表板检查
test_check "Grafana仪表板访问" "curl -s http://localhost:3000/api/dashboards | grep -q 'dashboards' >/dev/null 2>&1"

echo ""
echo "📋 10. 服务发现检查"
echo "--------------------------------------------------"

# Consul服务注册检查
test_check "Consul服务注册" "curl -s http://localhost:8202/v1/catalog/services | grep -q 'jobfirst' >/dev/null 2>&1"

# 服务健康状态检查
test_check "服务健康状态" "curl -s http://localhost:8202/v1/health/state/any | grep -q 'passing' >/dev/null 2>&1"

echo ""
echo "=================================================="
echo "📊 测试结果汇总"
echo "=================================================="

# 计算成功率
if [ $total_tests -gt 0 ]; then
    success_rate=$(echo "scale=1; $passed_tests * 100 / $total_tests" | bc)
else
    success_rate=0
fi

echo "📈 总测试数: $total_tests"
echo "✅ 通过测试: $passed_tests"
echo "❌ 失败测试: $failed_tests"
echo "📊 成功率: ${success_rate}%"

echo ""
echo "🔍 详细服务状态:"
echo "--------------------------------------------------"

# 显示容器状态
echo "🐳 Docker容器状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep jobfirst

echo ""
echo "🌐 端口监听状态:"
netstat -tuln | grep -E ':(8200|8201|8202|8203|8204|8205|8000|8001|8002|8003|3000|9090)' | sort

echo ""
echo "📋 服务访问地址:"
echo "--------------------------------------------------"
echo "🔗 Consul服务发现: http://localhost:8202"
echo "📊 Prometheus监控: http://localhost:9090"
echo "📈 Grafana仪表板: http://localhost:3000"
echo "🌐 API网关: http://localhost:8000"
echo "👥 用户服务: http://localhost:8001"
echo "📄 简历服务: http://localhost:8002"
echo "🤖 AI服务: http://localhost:8003"
echo "🏗️ 共享基础设施: http://localhost:8210"

echo ""
if [ $failed_tests -eq 0 ]; then
    echo "🎉 所有测试通过！JobFirst 集成模式运行正常"
    echo "💡 建议: 可以开始进行业务功能测试"
    echo "📝 下一步: 测试API接口和业务逻辑"
else
    echo "⚠️  部分测试失败，请检查相关服务"
    echo "💡 建议: 查看容器日志进行故障排查"
    echo "📝 下一步: 修复失败的服务后重新测试"
fi

echo ""
echo "📅 测试完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
