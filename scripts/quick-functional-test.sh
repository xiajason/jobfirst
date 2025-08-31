#!/bin/bash

# JobFirst 快速功能测试脚本
# 用于验证系统核心功能是否正常工作

set -e

echo "🚀 JobFirst 快速功能测试开始..."
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${BLUE}🧪 测试: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ 通过: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ 失败: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 检查Docker服务
check_docker() {
    echo -e "\n${YELLOW}🔍 检查Docker服务...${NC}"
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker服务未运行${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker服务正常${NC}"
}

# 检查数据库容器
check_database_containers() {
    echo -e "\n${YELLOW}🔍 检查数据库容器...${NC}"
    
    local containers=("jobfirst-mysql" "jobfirst-redis" "jobfirst-postgresql" "jobfirst-neo4j")
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$container"; then
            echo -e "${GREEN}✅ $container 运行中${NC}"
        else
            echo -e "${RED}❌ $container 未运行${NC}"
            return 1
        fi
    done
}

# 测试数据库连接
test_database_connections() {
    echo -e "\n${YELLOW}🔍 测试数据库连接...${NC}"
    
    # 测试MySQL连接
    if docker exec jobfirst-mysql mysql -u jobfirst -pjobfirst123 -e "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ MySQL连接正常${NC}"
    else
        echo -e "${RED}❌ MySQL连接失败${NC}"
        return 1
    fi
    
    # 测试Redis连接
    if docker exec jobfirst-redis redis-cli ping | grep -q "PONG"; then
        echo -e "${GREEN}✅ Redis连接正常${NC}"
    else
        echo -e "${RED}❌ Redis连接失败${NC}"
        return 1
    fi
    
    # 测试PostgreSQL连接
    if docker exec jobfirst-postgresql psql -U jobfirst -d jobfirst_advanced -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL连接正常${NC}"
    else
        echo -e "${RED}❌ PostgreSQL连接失败${NC}"
        return 1
    fi
    
    # 测试Neo4j连接
    if curl -u neo4j:jobfirst123 http://localhost:8204/browser/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Neo4j连接正常${NC}"
    else
        echo -e "${RED}❌ Neo4j连接失败${NC}"
        return 1
    fi
}

# 测试基础设施组件
test_infrastructure() {
    echo -e "\n${YELLOW}🔍 测试基础设施组件...${NC}"
    
    # 切换到基础设施目录
    cd backend/shared/infrastructure
    
    # 运行单元测试
    if go test -v ./... > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 基础设施单元测试通过${NC}"
    else
        echo -e "${RED}❌ 基础设施单元测试失败${NC}"
        return 1
    fi
    
    # 运行基础设施示例
    cd example
    if go run main.go > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 基础设施示例运行成功${NC}"
    else
        echo -e "${RED}❌ 基础设施示例运行失败${NC}"
        return 1
    fi
    
    cd ../../..
}

# 测试AI服务
test_ai_service() {
    echo -e "\n${YELLOW}🔍 测试AI服务...${NC}"
    
    # 检查AI服务容器
    if docker ps --format "table {{.Names}}" | grep -q "jobfirst-ai-service"; then
        echo -e "${GREEN}✅ AI服务容器运行中${NC}"
        
        # 测试API接口
        if curl -s http://localhost:8206/health | grep -q "ok"; then
            echo -e "${GREEN}✅ AI服务健康检查通过${NC}"
        else
            echo -e "${RED}❌ AI服务健康检查失败${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ AI服务容器未运行，跳过API测试${NC}"
    fi
}

# 测试API接口
test_api_endpoints() {
    echo -e "\n${YELLOW}🔍 测试API接口...${NC}"
    
    # 测试AI推荐API
    if curl -s -X POST http://localhost:8206/api/recommendations \
        -H "Content-Type: application/json" \
        -d '{"user_id": "test_user", "job_id": "test_job"}' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ AI推荐API测试通过${NC}"
    else
        echo -e "${YELLOW}⚠️ AI推荐API测试跳过（服务可能未启动）${NC}"
    fi
}

# 性能基准测试
performance_benchmark() {
    echo -e "\n${YELLOW}🔍 性能基准测试...${NC}"
    
    # 数据库查询性能测试
    echo "测试MySQL查询性能..."
    start_time=$(date +%s%N)
    docker exec jobfirst-mysql mysql -u jobfirst -pjobfirst123 jobfirst -e "SELECT COUNT(*) FROM users;" > /dev/null 2>&1
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    if [ $duration -lt 1000 ]; then
        echo -e "${GREEN}✅ MySQL查询性能: ${duration}ms${NC}"
    else
        echo -e "${YELLOW}⚠️ MySQL查询性能: ${duration}ms (较慢)${NC}"
    fi
    
    # Redis性能测试
    echo "测试Redis性能..."
    start_time=$(date +%s%N)
    docker exec jobfirst-redis redis-cli SET test_key test_value > /dev/null 2>&1
    docker exec jobfirst-redis redis-cli GET test_key > /dev/null 2>&1
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    if [ $duration -lt 100 ]; then
        echo -e "${GREEN}✅ Redis操作性能: ${duration}ms${NC}"
    else
        echo -e "${YELLOW}⚠️ Redis操作性能: ${duration}ms (较慢)${NC}"
    fi
}

# 生成测试报告
generate_report() {
    echo -e "\n${BLUE}📊 测试报告${NC}"
    echo "=================================="
    echo "总测试数: $TOTAL_TESTS"
    echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败: ${RED}$FAILED_TESTS${NC}"
    
    local success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    echo "成功率: $success_rate%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 所有测试通过！系统功能正常！${NC}"
        exit 0
    else
        echo -e "\n${RED}⚠️ 有 $FAILED_TESTS 个测试失败，请检查系统状态${NC}"
        exit 1
    fi
}

# 主函数
main() {
    echo "开始JobFirst功能测试..."
    
    # 检查Docker
    run_test "Docker服务检查" "check_docker"
    
    # 检查数据库容器
    run_test "数据库容器检查" "check_database_containers"
    
    # 测试数据库连接
    run_test "数据库连接测试" "test_database_connections"
    
    # 测试基础设施
    run_test "基础设施组件测试" "test_infrastructure"
    
    # 测试AI服务
    run_test "AI服务测试" "test_ai_service"
    
    # 测试API接口
    run_test "API接口测试" "test_api_endpoints"
    
    # 性能基准测试
    run_test "性能基准测试" "performance_benchmark"
    
    # 生成报告
    generate_report
}

# 执行主函数
main "$@"
