#!/bin/bash

# JobFirst数据库启动脚本
# 用于启动所有数据库服务

set -e

echo "🚀 启动JobFirst数据库服务..."

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

# 检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker未运行，请先启动Docker"
        exit 1
    fi
    log_success "Docker运行正常"
}

# 启动MySQL
start_mysql() {
    log_info "启动MySQL数据库..."
    docker-compose up -d mysql
    
    # 等待MySQL启动
    log_info "等待MySQL启动..."
    for i in {1..30}; do
        if docker exec jobfirst-mysql mysqladmin ping -u jobfirst -pjobfirst123 > /dev/null 2>&1; then
            log_success "MySQL启动成功"
            return 0
        fi
        sleep 2
    done
    
    log_error "MySQL启动超时"
    return 1
}

# 启动PostgreSQL
start_postgresql() {
    log_info "启动PostgreSQL数据库..."
    docker-compose -f docker-compose.enhanced.yml up -d postgresql
    
    # 等待PostgreSQL启动
    log_info "等待PostgreSQL启动..."
    for i in {1..30}; do
        if docker exec jobfirst-postgresql pg_isready -U jobfirst > /dev/null 2>&1; then
            log_success "PostgreSQL启动成功"
            return 0
        fi
        sleep 2
    done
    
    log_error "PostgreSQL启动超时"
    return 1
}

# 启动Neo4j
start_neo4j() {
    log_info "启动Neo4j图数据库..."
    docker-compose -f docker-compose.enhanced.yml up -d neo4j
    
    # 等待Neo4j启动
    log_info "等待Neo4j启动（这可能需要60-90秒）..."
    for i in {1..45}; do
        if curl -s -u neo4j:jobfirst123 http://localhost:8204/browser/ > /dev/null 2>&1; then
            log_success "Neo4j启动成功"
            return 0
        fi
        sleep 2
    done
    
    log_error "Neo4j启动超时"
    return 1
}

# 启动Redis（如果未运行）
start_redis() {
    if ! docker ps | grep -q jobfirst-redis; then
        log_info "启动Redis缓存..."
        docker-compose up -d redis
        sleep 5
    else
        log_info "Redis已在运行"
    fi
}

# 初始化数据库结构
init_databases() {
    log_info "初始化数据库结构..."
    
    # 初始化PostgreSQL
    log_info "初始化PostgreSQL表结构..."
    docker exec jobfirst-postgresql psql -U jobfirst -d jobfirst_advanced -c "
    CREATE TABLE IF NOT EXISTS ai_models (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        type VARCHAR(50) NOT NULL,
        provider VARCHAR(50) NOT NULL,
        config JSONB,
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS system_configs (
        id SERIAL PRIMARY KEY,
        config_key VARCHAR(100) UNIQUE NOT NULL,
        config_value TEXT,
        config_type VARCHAR(20) DEFAULT 'string',
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS vector_embeddings (
        id SERIAL PRIMARY KEY,
        entity_type VARCHAR(50) NOT NULL,
        entity_id BIGINT NOT NULL,
        embedding_vector REAL[],
        metadata JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(entity_type, entity_id)
    );
    " 2>/dev/null || log_warning "PostgreSQL初始化可能已存在"
    
    # 初始化Neo4j
    log_info "初始化Neo4j约束和索引..."
    curl -u neo4j:jobfirst123 -H "Content-Type: application/json" \
         -d '{"statements":[{"statement":"CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.id IS UNIQUE"}]}' \
         http://localhost:8204/db/neo4j/tx/commit 2>/dev/null || log_warning "Neo4j约束可能已存在"
    
    log_success "数据库结构初始化完成"
}

# 验证所有服务
verify_services() {
    log_info "验证所有数据库服务..."
    
    # 检查MySQL
    if docker exec jobfirst-mysql mysqladmin ping -u jobfirst -pjobfirst123 > /dev/null 2>&1; then
        log_success "MySQL: 运行正常"
    else
        log_error "MySQL: 连接失败"
        return 1
    fi
    
    # 检查Redis
    if docker exec jobfirst-redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis: 运行正常"
    else
        log_error "Redis: 连接失败"
        return 1
    fi
    
    # 检查PostgreSQL
    if docker exec jobfirst-postgresql pg_isready -U jobfirst > /dev/null 2>&1; then
        log_success "PostgreSQL: 运行正常"
    else
        log_error "PostgreSQL: 连接失败"
        return 1
    fi
    
    # 检查Neo4j
    if curl -s -u neo4j:jobfirst123 http://localhost:8204/browser/ > /dev/null 2>&1; then
        log_success "Neo4j: 运行正常"
    else
        log_error "Neo4j: 连接失败"
        return 1
    fi
    
    return 0
}

# 显示连接信息
show_connection_info() {
    echo ""
    log_info "数据库连接信息："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "MySQL:"
    echo "  主机: localhost"
    echo "  端口: 8200"
    echo "  数据库: jobfirst"
    echo "  用户: jobfirst"
    echo "  密码: jobfirst123"
    echo ""
    echo "Redis:"
    echo "  主机: localhost"
    echo "  端口: 8201"
    echo "  密码: (无)"
    echo ""
    echo "PostgreSQL:"
    echo "  主机: localhost"
    echo "  端口: 8203"
    echo "  数据库: jobfirst_advanced"
    echo "  用户: jobfirst"
    echo "  密码: jobfirst123"
    echo ""
    echo "Neo4j:"
    echo "  HTTP: http://localhost:8204"
    echo "  Bolt: localhost:8205"
    echo "  用户: jobfirst"
    echo "  密码: jobfirst123"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 主函数
main() {
    echo "JobFirst数据库启动脚本"
    echo "版本: 1.0"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 检查Docker
    check_docker
    
    # 启动服务
    start_redis
    start_mysql
    start_postgresql
    start_neo4j
    
    # 初始化数据库
    init_databases
    
    # 验证服务
    if verify_services; then
        log_success "所有数据库服务启动成功！"
        show_connection_info
    else
        log_error "部分服务启动失败，请检查日志"
        exit 1
    fi
}

# 执行主函数
main "$@"
