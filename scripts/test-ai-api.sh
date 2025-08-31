#!/bin/bash

# AI服务API测试脚本

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

# 基础URL
BASE_URL="http://localhost:8089"

# 测试健康检查
test_health_check() {
    log_info "Testing health check..."
    
    response=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "${BASE_URL}/health")
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        log_success "Health check passed"
        cat /tmp/health_response.json | jq '.' 2>/dev/null || cat /tmp/health_response.json
    else
        log_error "Health check failed with status code: $http_code"
        cat /tmp/health_response.json
    fi
    echo ""
}

# 测试职位推荐
test_job_recommendations() {
    log_info "Testing job recommendations..."
    
    response=$(curl -s -w "%{http_code}" -o /tmp/job_recommendations.json "${BASE_URL}/api/v1/recommendations/jobs/1?limit=5")
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        log_success "Job recommendations test passed"
        cat /tmp/job_recommendations.json | jq '.' 2>/dev/null || cat /tmp/job_recommendations.json
    else
        log_error "Job recommendations test failed with status code: $http_code"
        cat /tmp/job_recommendations.json
    fi
    echo ""
}

# 测试技能推荐
test_skill_recommendations() {
    log_info "Testing skill recommendations..."
    
    response=$(curl -s -w "%{http_code}" -o /tmp/skill_recommendations.json "${BASE_URL}/api/v1/recommendations/skills/1?limit=5")
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        log_success "Skill recommendations test passed"
        cat /tmp/skill_recommendations.json | jq '.' 2>/dev/null || cat /tmp/skill_recommendations.json
    else
        log_error "Skill recommendations test failed with status code: $http_code"
        cat /tmp/skill_recommendations.json
    fi
    echo ""
}

# 测试个性化推荐
test_personalized_recommendations() {
    log_info "Testing personalized recommendations..."
    
    # 创建临时JSON文件
    cat > /tmp/skills_request.json << EOF
{
    "skills": ["Java", "Spring Boot", "MySQL"]
}
EOF
    
    response=$(curl -s -w "%{http_code}" -o /tmp/personalized_recommendations.json \
        -X POST \
        -H "Content-Type: application/json" \
        -d @/tmp/skills_request.json \
        "${BASE_URL}/api/v1/recommendations/personalized/1?limit=5")
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        log_success "Personalized recommendations test passed"
        cat /tmp/personalized_recommendations.json | jq '.' 2>/dev/null || cat /tmp/personalized_recommendations.json
    else
        log_error "Personalized recommendations test failed with status code: $http_code"
        cat /tmp/personalized_recommendations.json
    fi
    echo ""
}

# 测试相似度计算
test_similarity_calculation() {
    log_info "Testing similarity calculation..."
    
    # 创建临时JSON文件
    cat > /tmp/similarity_request.json << EOF
{
    "skills1": ["Java", "Spring Boot", "MySQL"],
    "skills2": ["Java", "Spring Boot", "Redis"]
}
EOF
    
    response=$(curl -s -w "%{http_code}" -o /tmp/similarity_response.json \
        -X POST \
        -H "Content-Type: application/json" \
        -d @/tmp/similarity_request.json \
        "${BASE_URL}/api/v1/algorithms/similarity")
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        log_success "Similarity calculation test passed"
        cat /tmp/similarity_response.json | jq '.' 2>/dev/null || cat /tmp/similarity_response.json
    else
        log_error "Similarity calculation test failed with status code: $http_code"
        cat /tmp/similarity_response.json
    fi
    echo ""
}

# 测试技能匹配度计算
test_skill_match_calculation() {
    log_info "Testing skill match calculation..."
    
    # 创建临时JSON文件
    cat > /tmp/skill_match_request.json << EOF
{
    "required_skills": ["Java", "Spring Boot", "MySQL", "Redis"],
    "user_skills": ["Java", "Spring Boot", "MySQL"]
}
EOF
    
    response=$(curl -s -w "%{http_code}" -o /tmp/skill_match_response.json \
        -X POST \
        -H "Content-Type: application/json" \
        -d @/tmp/skill_match_request.json \
        "${BASE_URL}/api/v1/algorithms/skill-match")
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        log_success "Skill match calculation test passed"
        cat /tmp/skill_match_response.json | jq '.' 2>/dev/null || cat /tmp/skill_match_response.json
    else
        log_error "Skill match calculation test failed with status code: $http_code"
        cat /tmp/skill_match_response.json
    fi
    echo ""
}

# 检查服务是否运行
check_service() {
    log_info "Checking if AI service is running..."
    
    if curl -s "${BASE_URL}/health" > /dev/null 2>&1; then
        log_success "AI service is running"
        return 0
    else
        log_error "AI service is not running"
        return 1
    fi
}

# 清理临时文件
cleanup() {
    rm -f /tmp/health_response.json
    rm -f /tmp/job_recommendations.json
    rm -f /tmp/skill_recommendations.json
    rm -f /tmp/personalized_recommendations.json
    rm -f /tmp/similarity_response.json
    rm -f /tmp/skill_match_response.json
    rm -f /tmp/skills_request.json
    rm -f /tmp/similarity_request.json
    rm -f /tmp/skill_match_request.json
}

# 主函数
main() {
    echo "AI Service API Test"
    echo "=================="
    echo ""
    
    # 检查服务状态
    if ! check_service; then
        log_error "Please start the AI service first"
        exit 1
    fi
    
    # 运行测试
    test_health_check
    test_job_recommendations
    test_skill_recommendations
    test_personalized_recommendations
    test_similarity_calculation
    test_skill_match_calculation
    
    # 清理
    cleanup
    
    log_success "All tests completed!"
}

# 执行主函数
main "$@"
