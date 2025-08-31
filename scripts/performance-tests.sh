#!/bin/bash

# JobFirst Performance Tests
# 用于CI/CD中的性能验证

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

# 环境变量
ENVIRONMENT="${1:-staging}"
API_BASE_URL="${2:-http://localhost:8000}"
RESULTS_DIR="${3:-performance-results}"
CONCURRENT_USERS="${4:-10}"
TEST_DURATION="${5:-60}"

# 创建结果目录
mkdir -p "$RESULTS_DIR"

log_info "开始性能测试 - 环境: $ENVIRONMENT"
log_info "API基础URL: $API_BASE_URL"
log_info "并发用户数: $CONCURRENT_USERS"
log_info "测试持续时间: ${TEST_DURATION}秒"
log_info "结果目录: $RESULTS_DIR"

# 检查依赖工具
check_dependencies() {
    log_info "检查性能测试依赖工具..."
    
    if ! command -v ab >/dev/null 2>&1; then
        log_error "Apache Bench (ab) 未安装，请安装: brew install httpd"
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl 未安装"
        exit 1
    fi
    
    log_success "所有依赖工具已安装"
}

# 生成测试数据
generate_test_data() {
    log_info "生成测试数据..."
    
    # 创建测试用户数据
    cat > "$RESULTS_DIR/test_users.json" << EOF
[
  {"username": "testuser1", "email": "test1@example.com", "password": "testpass123"},
  {"username": "testuser2", "email": "test2@example.com", "password": "testpass123"},
  {"username": "testuser3", "email": "test3@example.com", "password": "testpass123"},
  {"username": "testuser4", "email": "test4@example.com", "password": "testpass123"},
  {"username": "testuser5", "email": "test5@example.com", "password": "testpass123"}
]
EOF
    
    log_success "测试数据生成完成"
}

# 测试API网关响应时间
test_gateway_response_time() {
    log_info "测试API网关响应时间..."
    
    local result_file="$RESULTS_DIR/gateway_response_time.txt"
    
    # 测试健康检查端点响应时间
    ab -n 100 -c 10 -g "$RESULTS_DIR/gateway_health_benchmark.tsv" \
       "$API_BASE_URL/health" > "$result_file" 2>&1
    
    # 提取关键指标
    local rps=$(grep "Requests per second" "$result_file" | awk '{print $4}')
    local mean_time=$(grep "Time per request" "$result_file" | head -1 | awk '{print $4}')
    local p95_time=$(grep "95%" "$result_file" | awk '{print $2}')
    
    log_info "网关响应时间测试结果:"
    log_info "  RPS: $rps"
    log_info "  平均响应时间: ${mean_time}ms"
    log_info "  95%响应时间: ${p95_time}ms"
    
    # 检查性能指标
    if (( $(echo "$mean_time < 100" | bc -l) )); then
        log_success "网关响应时间测试通过"
    else
        log_warning "网关响应时间较慢: ${mean_time}ms"
    fi
}

# 测试CORS预检请求性能
test_cors_performance() {
    log_info "测试CORS预检请求性能..."
    
    local result_file="$RESULTS_DIR/cors_performance.txt"
    
    # 测试CORS预检请求
    ab -n 50 -c 5 -m OPTIONS -H "Origin: http://localhost:3000" \
       -H "Access-Control-Request-Method: POST" \
       -H "Access-Control-Request-Headers: Content-Type,Authorization" \
       "$API_BASE_URL/api/v1/user/profile" > "$result_file" 2>&1
    
    local rps=$(grep "Requests per second" "$result_file" | awk '{print $4}')
    local mean_time=$(grep "Time per request" "$result_file" | head -1 | awk '{print $4}')
    
    log_info "CORS性能测试结果:"
    log_info "  RPS: $rps"
    log_info "  平均响应时间: ${mean_time}ms"
    
    if (( $(echo "$mean_time < 50" | bc -l) )); then
        log_success "CORS性能测试通过"
    else
        log_warning "CORS响应时间较慢: ${mean_time}ms"
    fi
}

# 测试认证中间件性能
test_auth_performance() {
    log_info "测试认证中间件性能..."
    
    local result_file="$RESULTS_DIR/auth_performance.txt"
    
    # 测试无效token的性能（模拟认证失败）
    ab -n 100 -c 10 -H "Authorization: Bearer invalid-token" \
       "$API_BASE_URL/api/v1/user/profile" > "$result_file" 2>&1
    
    local rps=$(grep "Requests per second" "$result_file" | awk '{print $4}')
    local mean_time=$(grep "Time per request" "$result_file" | head -1 | awk '{print $4}')
    
    log_info "认证性能测试结果:"
    log_info "  RPS: $rps"
    log_info "  平均响应时间: ${mean_time}ms"
    
    if (( $(echo "$mean_time < 20" | bc -l) )); then
        log_success "认证性能测试通过"
    else
        log_warning "认证响应时间较慢: ${mean_time}ms"
    fi
}

# 测试并发处理能力
test_concurrent_handling() {
    log_info "测试并发处理能力..."
    
    local result_file="$RESULTS_DIR/concurrent_performance.txt"
    
    # 测试不同并发级别的性能
    for concurrency in 5 10 20 50; do
        log_info "测试并发数: $concurrency"
        
        ab -n 200 -c "$concurrency" -g "$RESULTS_DIR/concurrent_${concurrency}.tsv" \
           "$API_BASE_URL/health" > "$RESULTS_DIR/concurrent_${concurrency}.txt" 2>&1
        
        local rps=$(grep "Requests per second" "$RESULTS_DIR/concurrent_${concurrency}.txt" | awk '{print $4}')
        local mean_time=$(grep "Time per request" "$RESULTS_DIR/concurrent_${concurrency}.txt" | head -1 | awk '{print $4}')
        
        log_info "  并发$concurrency - RPS: $rps, 平均时间: ${mean_time}ms"
    done
}

# 测试内存使用情况
test_memory_usage() {
    log_info "测试内存使用情况..."
    
    # 获取网关容器ID
    local container_id=$(docker ps --filter "name=jobfirst-enhanced-gateway" --format "{{.ID}}")
    
    if [ -n "$container_id" ]; then
        local memory_usage=$(docker stats --no-stream --format "table {{.MemUsage}}" "$container_id" | tail -1)
        log_info "网关内存使用: $memory_usage"
        
        # 提取内存使用量（MB）
        local memory_mb=$(echo "$memory_usage" | sed 's/MiB.*//')
        
        if [ "$memory_mb" -lt 100 ]; then
            log_success "内存使用正常: ${memory_mb}MB"
        else
            log_warning "内存使用较高: ${memory_mb}MB"
        fi
    else
        log_warning "无法获取网关容器信息"
    fi
}

# 测试CPU使用情况
test_cpu_usage() {
    log_info "测试CPU使用情况..."
    
    local container_id=$(docker ps --filter "name=jobfirst-enhanced-gateway" --format "{{.ID}}")
    
    if [ -n "$container_id" ]; then
        local cpu_usage=$(docker stats --no-stream --format "table {{.CPUPerc}}" "$container_id" | tail -1)
        log_info "网关CPU使用: $cpu_usage"
        
        # 提取CPU百分比
        local cpu_percent=$(echo "$cpu_usage" | sed 's/%.*//')
        
        if [ "$cpu_percent" -lt 50 ]; then
            log_success "CPU使用正常: ${cpu_percent}%"
        else
            log_warning "CPU使用较高: ${cpu_percent}%"
        fi
    else
        log_warning "无法获取网关容器信息"
    fi
}

# 生成性能报告
generate_performance_report() {
    log_info "生成性能测试报告..."
    
    local report_file="$RESULTS_DIR/performance_report.md"
    
    cat > "$report_file" << EOF
# JobFirst 性能测试报告

## 测试环境
- **环境**: $ENVIRONMENT
- **API基础URL**: $API_BASE_URL
- **测试时间**: $(date)
- **并发用户数**: $CONCURRENT_USERS
- **测试持续时间**: ${TEST_DURATION}秒

## 测试结果摘要

### API网关响应时间
- **测试端点**: /health
- **并发数**: 10
- **请求数**: 100

### CORS预检请求性能
- **测试端点**: OPTIONS /api/v1/user/profile
- **并发数**: 5
- **请求数**: 50

### 认证中间件性能
- **测试端点**: /api/v1/user/profile (无效token)
- **并发数**: 10
- **请求数**: 100

### 并发处理能力
- **测试端点**: /health
- **并发级别**: 5, 10, 20, 50
- **每个级别请求数**: 200

## 性能指标

### 响应时间要求
- **健康检查**: < 100ms
- **CORS预检**: < 50ms
- **认证验证**: < 20ms

### 资源使用要求
- **内存使用**: < 100MB
- **CPU使用**: < 50%

## 详细结果

请查看以下文件获取详细测试结果：
- \`gateway_response_time.txt\`: 网关响应时间测试
- \`cors_performance.txt\`: CORS性能测试
- \`auth_performance.txt\`: 认证性能测试
- \`concurrent_*.txt\`: 并发性能测试
- \`*.tsv\`: 详细性能数据（可用于图表生成）

## 建议

1. 如果响应时间超过阈值，考虑优化代码逻辑
2. 如果资源使用过高，考虑调整容器资源配置
3. 定期运行性能测试，监控性能趋势
4. 在生产环境部署前进行压力测试

EOF
    
    log_success "性能测试报告已生成: $report_file"
}

# 主测试流程
main() {
    log_info "=== JobFirst Performance Tests ==="
    log_info "开始时间: $(date)"
    
    # 检查依赖
    check_dependencies
    
    # 生成测试数据
    generate_test_data
    
    # 执行性能测试
    test_gateway_response_time
    test_cors_performance
    test_auth_performance
    test_concurrent_handling
    test_memory_usage
    test_cpu_usage
    
    # 生成报告
    generate_performance_report
    
    log_info "=== 性能测试完成 ==="
    log_info "结束时间: $(date)"
    log_info "结果保存在: $RESULTS_DIR"
    
    log_success "性能测试执行完成！"
}

# 脚本入口
main "$@"
