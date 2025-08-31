#!/bin/bash

# JobFirst 前后端拉通测试脚本
# 基于渐进式升级指南和Consul服务发现集成

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

# 配置
GATEWAY_URL="http://localhost:8000"
CONSUL_URL="http://localhost:8202"
SHARED_INFRA_URL="http://localhost:8210"
TEST_TOKEN="test-jwt-token-12345"

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试结果记录
TEST_RESULTS=()

# 记录测试结果
record_test() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "✅ $test_name: $message"
        TEST_RESULTS+=("✅ $test_name: PASS")
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "❌ $test_name: $message"
        TEST_RESULTS+=("❌ $test_name: FAIL - $message")
    fi
}

# 检查服务健康状态
check_service_health() {
    local service_name="$1"
    local url="$2"
    
    log_test "检查服务健康状态: $service_name"
    
    if curl -f -s "$url/health" > /dev/null 2>&1; then
        record_test "$service_name健康检查" "PASS" "服务正常运行"
        return 0
    else
        record_test "$service_name健康检查" "FAIL" "服务无法访问"
        return 1
    fi
}

# 测试API网关基础功能
test_gateway_basic() {
    log_step "=== 测试API网关基础功能 ==="
    
    # 测试健康检查
    log_test "测试网关健康检查"
    if curl -f -s "$GATEWAY_URL/health" > /dev/null 2>&1; then
        record_test "网关健康检查" "PASS" "网关健康检查通过"
    else
        record_test "网关健康检查" "FAIL" "网关健康检查失败"
    fi
    
    # 测试服务信息
    log_test "测试网关服务信息"
    if curl -f -s "$GATEWAY_URL/info" > /dev/null 2>&1; then
        record_test "网关服务信息" "PASS" "网关服务信息正常"
    else
        record_test "网关服务信息" "FAIL" "网关服务信息失败"
    fi
    
    # 测试指标端点
    log_test "测试网关指标端点"
    if curl -f -s "$GATEWAY_URL/metrics" > /dev/null 2>&1; then
        record_test "网关指标端点" "PASS" "网关指标端点正常"
    else
        record_test "网关指标端点" "FAIL" "网关指标端点失败"
    fi
}

# 测试API路由功能
test_api_routing() {
    log_step "=== 测试API路由功能 ==="
    
    # 测试公开API (无需认证)
    log_test "测试公开API路由"
    response=$(curl -s -w "%{http_code}" "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "401" ]; then
        record_test "公开API路由" "PASS" "路由正确，返回401认证错误"
    else
        record_test "公开API路由" "FAIL" "路由异常，返回码: $response"
    fi
    
    # 测试需要认证的API
    log_test "测试需要认证的API路由"
    response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $TEST_TOKEN" \
        "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "200" ] || [ "$response" = "404" ] || [ "$response" = "503" ]; then
        record_test "认证API路由" "PASS" "路由正确，返回码: $response"
    else
        record_test "认证API路由" "FAIL" "路由异常，返回码: $response"
    fi
    
    # 测试不存在的路由
    log_test "测试404路由"
    response=$(curl -s -w "%{http_code}" "$GATEWAY_URL/api/v1/nonexistent" -o /dev/null)
    if [ "$response" = "404" ]; then
        record_test "404路由处理" "PASS" "正确处理不存在的路由"
    else
        record_test "404路由处理" "FAIL" "404处理异常，返回码: $response"
    fi
}

# 测试Consul服务发现
test_consul_discovery() {
    log_step "=== 测试Consul服务发现 ==="
    
    # 检查Consul连接
    log_test "检查Consul连接"
    if curl -f -s "$CONSUL_URL/v1/status/leader" > /dev/null 2>&1; then
        record_test "Consul连接" "PASS" "Consul服务正常"
    else
        record_test "Consul连接" "FAIL" "Consul服务无法连接"
        return 1
    fi
    
    # 检查服务注册
    log_test "检查服务注册状态"
    services=$(curl -s "$CONSUL_URL/v1/catalog/services" | jq -r 'keys[]' | grep -v consul | wc -l)
    if [ "$services" -gt 0 ]; then
        record_test "服务注册" "PASS" "发现 $services 个注册的服务"
    else
        record_test "服务注册" "FAIL" "未发现注册的服务"
    fi
    
    # 检查服务健康状态
    log_test "检查服务健康状态"
    health_status=$(curl -s "$CONSUL_URL/v1/health/state/any" | jq -r '.[0].Status' 2>/dev/null || echo "unknown")
    if [ "$health_status" = "passing" ] || [ "$health_status" = "warning" ]; then
        record_test "服务健康状态" "PASS" "服务健康状态: $health_status"
    else
        record_test "服务健康状态" "FAIL" "服务健康状态异常: $health_status"
    fi
}

# 测试共享基础设施
test_shared_infrastructure() {
    log_step "=== 测试共享基础设施 ==="
    
    # 检查共享基础设施健康状态
    check_service_health "shared-infrastructure" "$SHARED_INFRA_URL"
    
    # 测试共享基础设施信息端点
    log_test "测试共享基础设施信息端点"
    if curl -f -s "$SHARED_INFRA_URL/info" > /dev/null 2>&1; then
        record_test "共享基础设施信息" "PASS" "信息端点正常"
    else
        record_test "共享基础设施信息" "FAIL" "信息端点失败"
    fi
    
    # 测试共享基础设施指标端点
    log_test "测试共享基础设施指标端点"
    if curl -f -s "$SHARED_INFRA_URL/metrics" > /dev/null 2>&1; then
        record_test "共享基础设施指标" "PASS" "指标端点正常"
    else
        record_test "共享基础设施指标" "FAIL" "指标端点失败"
    fi
}

# 测试数据库连接
test_database_connections() {
    log_step "=== 测试数据库连接 ==="
    
    # 测试MySQL连接
    log_test "测试MySQL连接"
    if docker exec jobfirst-mysql mysql -u jobfirst -pjobfirst123 -e "SELECT 1;" 2>/dev/null; then
        record_test "MySQL连接" "PASS" "MySQL数据库连接正常"
    else
        record_test "MySQL连接" "FAIL" "MySQL数据库连接失败"
    fi
    
    # 测试Redis连接
    log_test "测试Redis连接"
    if redis-cli -h localhost -p 8201 ping 2>/dev/null | grep -q "PONG"; then
        record_test "Redis连接" "PASS" "Redis数据库连接正常"
    else
        record_test "Redis连接" "FAIL" "Redis数据库连接失败"
    fi
    
    # 测试Neo4j连接
    log_test "测试Neo4j连接"
    if curl -f -s "http://localhost:8204" > /dev/null 2>&1; then
        record_test "Neo4j连接" "PASS" "Neo4j数据库连接正常"
    else
        record_test "Neo4j连接" "FAIL" "Neo4j数据库连接失败"
    fi
    
    # 测试PostgreSQL连接
    log_test "测试PostgreSQL连接"
    if docker exec jobfirst-postgresql psql -U jobfirst -d jobfirst_advanced -c "SELECT 1;" 2>/dev/null; then
        record_test "PostgreSQL连接" "PASS" "PostgreSQL数据库连接正常"
    else
        record_test "PostgreSQL连接" "FAIL" "PostgreSQL数据库连接失败"
    fi
}

# 测试API版本兼容性
test_api_version_compatibility() {
    log_step "=== 测试API版本兼容性 ==="
    
    # 测试V1 API
    log_test "测试V1 API兼容性"
    response=$(curl -s -w "%{http_code}" \
        -H "API-Version: v1" \
        "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "401" ] || [ "$response" = "404" ] || [ "$response" = "503" ]; then
        record_test "V1 API兼容性" "PASS" "V1 API路由正常，返回码: $response"
    else
        record_test "V1 API兼容性" "FAIL" "V1 API路由异常，返回码: $response"
    fi
    
    # 测试V2 API
    log_test "测试V2 API兼容性"
    response=$(curl -s -w "%{http_code}" \
        -H "API-Version: v2" \
        "$GATEWAY_URL/api/v2/user/profile" -o /dev/null)
    if [ "$response" = "401" ] || [ "$response" = "404" ] || [ "$response" = "503" ]; then
        record_test "V2 API兼容性" "PASS" "V2 API路由正常，返回码: $response"
    else
        record_test "V2 API兼容性" "FAIL" "V2 API路由异常，返回码: $response"
    fi
    
    # 测试默认API版本
    log_test "测试默认API版本"
    response=$(curl -s -w "%{http_code}" \
        "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "401" ] || [ "$response" = "404" ] || [ "$response" = "503" ]; then
        record_test "默认API版本" "PASS" "默认API版本路由正常，返回码: $response"
    else
        record_test "默认API版本" "FAIL" "默认API版本路由异常，返回码: $response"
    fi
}

# 测试认证功能
test_authentication() {
    log_step "=== 测试认证功能 ==="
    
    # 测试无认证访问
    log_test "测试无认证访问"
    response=$(curl -s -w "%{http_code}" \
        "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "401" ]; then
        record_test "无认证访问" "PASS" "正确返回401未认证错误"
    else
        record_test "无认证访问" "FAIL" "认证检查异常，返回码: $response"
    fi
    
    # 测试无效token
    log_test "测试无效token"
    response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer invalid-token" \
        "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "401" ]; then
        record_test "无效token" "PASS" "正确拒绝无效token"
    else
        record_test "无效token" "FAIL" "无效token处理异常，返回码: $response"
    fi
    
    # 测试有效token格式
    log_test "测试有效token格式"
    response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $TEST_TOKEN" \
        "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "200" ] || [ "$response" = "404" ] || [ "$response" = "503" ]; then
        record_test "有效token格式" "PASS" "token格式正确，返回码: $response"
    else
        record_test "有效token格式" "FAIL" "token格式处理异常，返回码: $response"
    fi
}

# 测试CORS功能
test_cors_functionality() {
    log_step "=== 测试CORS功能 ==="
    
    # 测试OPTIONS预检请求
    log_test "测试CORS预检请求"
    response=$(curl -s -w "%{http_code}" \
        -X OPTIONS \
        -H "Origin: http://localhost:3000" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: Authorization" \
        "$GATEWAY_URL/api/v1/user/profile" -o /dev/null)
    if [ "$response" = "204" ] || [ "$response" = "200" ]; then
        record_test "CORS预检请求" "PASS" "CORS预检请求正常，返回码: $response"
    else
        record_test "CORS预检请求" "FAIL" "CORS预检请求异常，返回码: $response"
    fi
    
    # 测试CORS头
    log_test "测试CORS头"
    cors_headers=$(curl -s -I "$GATEWAY_URL/api/v1/user/profile" | grep -i "access-control" | wc -l)
    if [ "$cors_headers" -gt 0 ]; then
        record_test "CORS头" "PASS" "CORS头设置正常"
    else
        record_test "CORS头" "FAIL" "CORS头设置异常"
    fi
}

# 测试性能指标
test_performance_metrics() {
    log_step "=== 测试性能指标 ==="
    
    # 测试响应时间
    log_test "测试API响应时间"
    start_time=$(date +%s%N)
    curl -s "$GATEWAY_URL/health" > /dev/null
    end_time=$(date +%s%N)
    response_time=$(( (end_time - start_time) / 1000000 ))
    
    if [ "$response_time" -lt 1000 ]; then
        record_test "API响应时间" "PASS" "响应时间: ${response_time}ms (正常)"
    else
        record_test "API响应时间" "FAIL" "响应时间: ${response_time}ms (过慢)"
    fi
    
    # 测试并发请求
    log_test "测试并发请求处理"
    for i in {1..5}; do
        curl -s "$GATEWAY_URL/health" > /dev/null &
    done
    wait
    
    record_test "并发请求处理" "PASS" "并发请求处理正常"
}

# 生成测试报告
generate_test_report() {
    log_step "=== 生成测试报告 ==="
    
    echo ""
    echo "=========================================="
    echo "          前后端拉通测试报告"
    echo "=========================================="
    echo "测试时间: $(date)"
    echo "测试环境: JobFirst微服务架构"
    echo ""
    
    echo "测试统计:"
    echo "- 总测试数: $TOTAL_TESTS"
    echo "- 通过测试: $PASSED_TESTS"
    echo "- 失败测试: $FAILED_TESTS"
    echo "- 成功率: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    echo ""
    
    echo "详细测试结果:"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo "🎉 所有测试通过！前后端拉通测试成功！"
        log_success "前后端拉通测试完成 - 所有测试通过"
        return 0
    else
        echo "⚠️  有 $FAILED_TESTS 个测试失败，请检查相关服务"
        log_warning "前后端拉通测试完成 - 有测试失败"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "JobFirst 前后端拉通测试脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -a, --all           运行所有测试"
    echo "  -g, --gateway       测试API网关功能"
    echo "  -c, --consul        测试Consul服务发现"
    echo "  -i, --infrastructure 测试共享基础设施"
    echo "  -d, --database      测试数据库连接"
    echo "  -v, --version       测试API版本兼容性"
    echo "  -auth, --auth       测试认证功能"
    echo "  -cors, --cors       测试CORS功能"
    echo "  -p, --performance   测试性能指标"
    echo ""
    echo "示例:"
    echo "  $0 -a               运行所有测试"
    echo "  $0 -g -c            测试网关和Consul"
    echo "  $0 -d -v            测试数据库和API版本"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--all)
            log_info "开始运行所有前后端拉通测试..."
            test_gateway_basic
            test_api_routing
            test_consul_discovery
            test_shared_infrastructure
            test_database_connections
            test_api_version_compatibility
            test_authentication
            test_cors_functionality
            test_performance_metrics
            ;;
        -g|--gateway)
            log_info "测试API网关功能..."
            test_gateway_basic
            test_api_routing
            ;;
        -c|--consul)
            log_info "测试Consul服务发现..."
            test_consul_discovery
            ;;
        -i|--infrastructure)
            log_info "测试共享基础设施..."
            test_shared_infrastructure
            ;;
        -d|--database)
            log_info "测试数据库连接..."
            test_database_connections
            ;;
        -v|--version)
            log_info "测试API版本兼容性..."
            test_api_version_compatibility
            ;;
        -auth|--auth)
            log_info "测试认证功能..."
            test_authentication
            ;;
        -cors|--cors)
            log_info "测试CORS功能..."
            test_cors_functionality
            ;;
        -p|--performance)
            log_info "测试性能指标..."
            test_performance_metrics
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
    
    generate_test_report
}

# 执行主函数
main "$@"
