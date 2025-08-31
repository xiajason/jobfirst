#!/bin/bash

# JobFirst Smoke Tests
# 用于CI/CD中的基础功能验证

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

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 记录测试结果
record_test() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "$test_name: $message"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "$test_name: $message"
    fi
}

# 环境变量
ENVIRONMENT="${1:-staging}"
API_BASE_URL="${2:-http://localhost:8000}"
TIMEOUT=30

log_info "开始Smoke测试 - 环境: $ENVIRONMENT"
log_info "API基础URL: $API_BASE_URL"
log_info "超时设置: ${TIMEOUT}秒"

# 等待服务启动
wait_for_service() {
    local url="$1"
    local service_name="$2"
    local max_attempts=30
    local attempt=1
    
    log_info "等待 $service_name 服务启动..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            log_success "$service_name 服务已启动"
            return 0
        fi
        
        log_info "尝试 $attempt/$max_attempts - $service_name 未就绪，等待5秒..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    log_error "$service_name 服务启动超时"
    return 1
}

# 测试API网关健康检查
test_gateway_health() {
    log_info "测试API网关健康检查"
    
    if curl -s -f "$API_BASE_URL/health" > /dev/null 2>&1; then
        record_test "API网关健康检查" "PASS" "网关服务正常"
    else
        record_test "API网关健康检查" "FAIL" "网关服务不可用"
        return 1
    fi
}

# 测试API网关信息端点
test_gateway_info() {
    log_info "测试API网关信息端点"
    
    local response=$(curl -s "$API_BASE_URL/info" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        record_test "API网关信息端点" "PASS" "网关信息获取成功"
    else
        record_test "API网关信息端点" "FAIL" "网关信息获取失败"
    fi
}

# 测试CORS预检请求
test_cors_preflight() {
    log_info "测试CORS预检请求"
    
    local response=$(curl -s -X OPTIONS \
        -H "Origin: http://localhost:3000" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type,Authorization" \
        "$API_BASE_URL/api/v1/user/profile" \
        -w "%{http_code}" \
        -o /dev/null)
    
    if [ "$response" = "204" ] || [ "$response" = "200" ]; then
        record_test "CORS预检请求" "PASS" "CORS配置正确"
    else
        record_test "CORS预检请求" "FAIL" "CORS配置异常，状态码: $response"
    fi
}

# 测试未认证访问
test_unauthenticated_access() {
    log_info "测试未认证访问"
    
    local response=$(curl -s -w "%{http_code}" \
        "$API_BASE_URL/api/v1/user/profile" \
        -o /dev/null)
    
    if [ "$response" = "401" ]; then
        record_test "未认证访问" "PASS" "正确返回401未授权"
    else
        record_test "未认证访问" "FAIL" "期望401，实际返回: $response"
    fi
}

# 测试无效token
test_invalid_token() {
    log_info "测试无效token"
    
    local response=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer invalid-token" \
        "$API_BASE_URL/api/v1/user/profile" \
        -o /dev/null)
    
    if [ "$response" = "401" ]; then
        record_test "无效token" "PASS" "正确拒绝无效token"
    else
        record_test "无效token" "FAIL" "期望401，实际返回: $response"
    fi
}

# 测试公开路径
test_public_paths() {
    log_info "测试公开路径"
    
    # 测试健康检查端点
    local response=$(curl -s -w "%{http_code}" \
        "$API_BASE_URL/health" \
        -o /dev/null)
    
    if [ "$response" = "200" ]; then
        record_test "公开路径访问" "PASS" "健康检查端点可正常访问"
    else
        record_test "公开路径访问" "FAIL" "健康检查端点访问失败，状态码: $response"
    fi
}

# 测试数据库连接（如果可用）
test_database_connections() {
    log_info "测试数据库连接"
    
    # 检查MySQL连接
    if command -v mysql >/dev/null 2>&1; then
        if mysql -h localhost -P 8200 -u jobfirst -pjobfirst123 -e "SELECT 1;" >/dev/null 2>&1; then
            record_test "MySQL连接" "PASS" "MySQL数据库连接正常"
        else
            # 尝试使用docker exec连接
            if docker exec jobfirst-mysql mysql -u jobfirst -pjobfirst123 -e "SELECT 1;" >/dev/null 2>&1; then
                record_test "MySQL连接" "PASS" "MySQL数据库连接正常（通过Docker）"
            else
                record_test "MySQL连接" "FAIL" "MySQL数据库连接失败"
            fi
        fi
    else
        # 尝试使用docker exec连接
        if docker exec jobfirst-mysql mysql -u jobfirst -pjobfirst123 -e "SELECT 1;" >/dev/null 2>&1; then
            record_test "MySQL连接" "PASS" "MySQL数据库连接正常（通过Docker）"
        else
            log_warning "MySQL客户端不可用，跳过MySQL连接测试"
        fi
    fi
    
    # 检查Redis连接
    if command -v redis-cli >/dev/null 2>&1; then
        if redis-cli -h localhost -p 8201 ping >/dev/null 2>&1; then
            record_test "Redis连接" "PASS" "Redis数据库连接正常"
        else
            record_test "Redis连接" "FAIL" "Redis数据库连接失败"
        fi
    else
        log_warning "Redis客户端不可用，跳过Redis连接测试"
    fi
}

# 测试服务发现（如果Consul可用）
test_service_discovery() {
    log_info "测试服务发现"
    
    if curl -s -f "http://localhost:8500/v1/status/leader" >/dev/null 2>&1; then
        record_test "Consul服务发现" "PASS" "Consul服务正常运行"
    else
        log_warning "Consul服务不可用，跳过服务发现测试"
    fi
}

# 主测试流程
main() {
    log_info "=== JobFirst Smoke Tests ==="
    log_info "开始时间: $(date)"
    
    # 等待API网关启动
    if ! wait_for_service "$API_BASE_URL/health" "API Gateway"; then
        log_error "API网关启动失败，退出测试"
        exit 1
    fi
    
    # 执行测试
    test_gateway_health
    test_gateway_info
    test_cors_preflight
    test_unauthenticated_access
    test_invalid_token
    test_public_paths
    test_database_connections
    test_service_discovery
    
    # 输出测试结果
    echo
    log_info "=== 测试结果汇总 ==="
    log_info "总测试数: $TOTAL_TESTS"
    log_success "通过测试: $PASSED_TESTS"
    if [ $FAILED_TESTS -gt 0 ]; then
        log_error "失败测试: $FAILED_TESTS"
    else
        log_success "失败测试: $FAILED_TESTS"
    fi
    
    local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    log_info "通过率: ${pass_rate}%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "所有Smoke测试通过！"
        exit 0
    else
        log_error "Smoke测试失败，请检查服务状态"
        exit 1
    fi
}

# 脚本入口
main "$@"
