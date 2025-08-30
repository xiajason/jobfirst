#!/bin/bash

echo "🧹 JobFirst 全面Docker环境清理脚本"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 确认清理操作
echo -e "${YELLOW}⚠️  此操作将清理所有Docker容器、镜像、卷和网络${NC}"
echo "   包括："
echo "   - 所有JobFirst相关容器"
echo "   - 所有Talent Shared服务"
echo "   - 所有Looma CRM服务"
echo "   - 所有Zervi服务"
echo "   - 所有Poetry服务"
echo "   - 所有Kong API网关服务"
echo "   - 所有Neo4j图数据库服务"
echo "   - 所有大模型相关服务 (transformers, weaviate)"
echo "   - 所有监控服务 (Prometheus, Grafana, Kibana)"
echo "   - 所有搜索引擎 (Elasticsearch)"
echo "   - 所有相关镜像、卷和网络"
echo ""
read -p "是否继续全面清理？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ 清理操作已取消${NC}"
    exit 1
fi

echo ""
echo "🛑 第一步：停止所有运行中的容器..."
echo "=================================="

# 停止所有运行中的容器
echo "停止所有运行中的容器..."
docker stop $(docker ps -q) 2>/dev/null || true

echo -e "${GREEN}✅ 所有容器已停止${NC}"

echo ""
echo "🗑️  第二步：删除所有相关容器..."
echo "================================"

# JobFirst相关容器
echo "删除JobFirst相关容器..."
docker rm -f jobfirst-user jobfirst-statistics jobfirst-resume jobfirst-points jobfirst-storage jobfirst-web jobfirst-gateway jobfirst-mysql jobfirst-consul jobfirst-redis 2>/dev/null || true

# Talent Shared相关容器
echo "删除Talent Shared相关容器..."
docker rm -f talent_shared_redis talent_shared_health_checker talent_shared_neo4j_manager talent_shared_neo4j talent_shared_geo_analytics talent_shared_data_sync talent_shared_ai_model_manager talent_shared_kong talent_shared_kibana talent_shared_mysql talent_shared_elasticsearch talent_shared_kong_db talent_shared_grafana talent_shared_prometheus 2>/dev/null || true

# Looma CRM相关容器
echo "删除Looma CRM相关容器..."
docker rm -f talent_crm_app talent_crm_nginx talent_crm_kibana talent_crm_grafana talent_crm_weaviate talent_crm_elasticsearch talent_crm_neo4j talent_crm_t2v_transformers talent_crm_prometheus talent_crm_redis talent_crm_postgres 2>/dev/null || true

# Zervi相关容器
echo "删除Zervi相关容器..."
docker rm -f zervi-redis zervi-postgres zervi-postgres-dev zervi-redis-dev 2>/dev/null || true

# Poetry相关容器
echo "删除Poetry相关容器..."
docker rm -f poetry_shared_memcached 2>/dev/null || true

# 其他可能的容器
echo "删除其他相关容器..."
docker rm -f $(docker ps -a --format "{{.Names}}" | grep -E "(jobfirst|talent|looma|zervi|poetry|kong|monica|neo4j|transformers|weaviate|elasticsearch|prometheus|grafana|kibana)") 2>/dev/null || true

echo -e "${GREEN}✅ 所有相关容器已删除${NC}"

echo ""
echo "🗑️  第三步：删除所有相关镜像..."
echo "================================"

# 删除相关镜像
echo "删除JobFirst相关镜像..."
docker rmi -f jobfirst-user jobfirst-statistics jobfirst-resume jobfirst-points jobfirst-storage jobfirst-web jobfirst-gateway 2>/dev/null || true

# 删除大模型相关镜像
echo "删除大模型相关镜像..."
docker rmi -f semitechnologies/transformers-inference:sentence-transformers-multi-qa-MiniLM-L6-cos-v1 2>/dev/null || true
docker rmi -f semitechnologies/weaviate:1.22.4 2>/dev/null || true

# 删除其他相关镜像
echo "删除其他相关镜像..."
docker rmi -f looma_crm-talent_crm_app:latest 2>/dev/null || true
docker rmi -f zervi-go-postgres:latest 2>/dev/null || true
docker rmi -f neo4j:5.15-community 2>/dev/null || true
docker rmi -f kong:3.4.0 2>/dev/null || true

# 删除未使用的镜像
echo "删除未使用的镜像..."
docker image prune -f

echo -e "${GREEN}✅ 所有相关镜像已删除${NC}"

echo ""
echo "🗑️  第四步：删除所有相关卷..."
echo "=============================="

# 删除所有相关卷
echo "删除JobFirst相关卷..."
docker volume rm jobfirst_consul_data jobfirst_mysql_data jobfirst_redis_data jobfirst_storage_data 2>/dev/null || true

echo "删除Talent Shared相关卷..."
docker volume rm looma_crm_neo4j_data looma_crm_neo4j_import looma_crm_neo4j_logs looma_crm_neo4j_plugins shared-infrastructure_neo4j_data shared-infrastructure_neo4j_import shared-infrastructure_neo4j_logs shared-infrastructure_neo4j_plugins 2>/dev/null || true

echo "删除其他相关卷..."
docker volume rm $(docker volume ls --format "{{.Name}}" | grep -E "(jobfirst|talent|looma|zervi|poetry|kong|monica|neo4j|elasticsearch|prometheus|grafana|kibana)") 2>/dev/null || true

# 删除未使用的卷
echo "删除未使用的卷..."
docker volume prune -f

echo -e "${GREEN}✅ 所有相关卷已删除${NC}"

echo ""
echo "🗑️  第五步：删除所有相关网络..."
echo "================================"

# 删除相关网络
echo "删除JobFirst相关网络..."
docker network rm jobfirst-network jobfirst_jobfirst-dev-network 2>/dev/null || true

echo "删除其他相关网络..."
docker network rm $(docker network ls --format "{{.Name}}" | grep -E "(jobfirst|talent|looma|zervi|poetry|kong|monica|neo4j)") 2>/dev/null || true

# 删除未使用的网络
echo "删除未使用的网络..."
docker network prune -f

echo -e "${GREEN}✅ 所有相关网络已删除${NC}"

echo ""
echo "🧹 第六步：清理Docker系统..."
echo "============================"

# 清理未使用的容器
echo "清理未使用的容器..."
docker container prune -f

# 清理构建缓存
echo "清理构建缓存..."
docker builder prune -f

# 清理系统
echo "清理Docker系统..."
docker system prune -f

echo -e "${GREEN}✅ Docker系统清理完成${NC}"

echo ""
echo "📊 清理结果统计..."
echo "=================="

# 统计清理结果
echo "📋 清理后的状态:"
echo "   - 容器: $(docker ps -a --format 'table {{.Names}}' | grep -c jobfirst || echo 0) 个JobFirst容器"
echo "   - 镜像: $(docker images --format 'table {{.Repository}}' | grep -c jobfirst || echo 0) 个JobFirst镜像"
echo "   - 卷: $(docker volume ls --format 'table {{.Name}}' | grep -c jobfirst || echo 0) 个JobFirst卷"
echo "   - 网络: $(docker network ls --format 'table {{.Name}}' | grep -c jobfirst || echo 0) 个JobFirst网络"

echo ""
echo "📋 剩余容器:"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | head -10

echo ""
echo "📋 剩余镜像:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -10

echo ""
echo -e "${GREEN}✅ 全面Docker环境清理完成！${NC}"
echo ""
echo "🚀 现在可以启动干净的开发环境:"
echo "   1. 环境准备: ./scripts/prepare-dev-environment.sh"
echo "   2. 端口迁移: ./scripts/migrate-ports.sh"
echo "   3. 启动开发: ./dev-start.sh"
echo ""
echo "💡 提示:"
echo "   - 所有第三方服务已被清理"
echo "   - 所有大模型相关容器已被删除"
echo "   - 所有监控和运维服务已被清理"
echo "   - 现在可以专注于JobFirst开发"
