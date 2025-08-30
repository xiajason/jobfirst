#!/bin/bash

echo "🧹 JobFirst Docker环境清理脚本"
echo "================================"

# 确认清理操作
echo "⚠️  此操作将清理所有Docker容器、镜像、卷和网络"
echo "   包括："
echo "   - 所有JobFirst相关容器"
echo "   - 所有JobFirst相关镜像"
echo "   - 所有JobFirst相关卷"
echo "   - 所有JobFirst相关网络"
echo "   - 所有悬空镜像和容器"
echo ""
read -p "是否继续清理？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 清理操作已取消"
    exit 1
fi

echo "🛑 停止所有运行中的容器..."
docker stop $(docker ps -q) 2>/dev/null || true

echo "🗑️  删除所有JobFirst相关容器..."
docker rm -f jobfirst-user jobfirst-statistics jobfirst-resume jobfirst-points jobfirst-storage jobfirst-web jobfirst-gateway jobfirst-mysql jobfirst-consul jobfirst-redis 2>/dev/null || true

echo "🗑️  删除所有JobFirst相关镜像..."
docker rmi -f jobfirst-user jobfirst-statistics jobfirst-resume jobfirst-points jobfirst-storage jobfirst-web jobfirst-gateway 2>/dev/null || true

echo "🗑️  删除所有JobFirst相关卷..."
docker volume rm jobfirst_consul_data jobfirst_mysql_data jobfirst_redis_data jobfirst_storage_data 2>/dev/null || true

echo "🗑️  删除所有Neo4j相关容器..."
docker rm -f talent_shared_neo4j talent_crm_neo4j talent_shared_neo4j_manager 2>/dev/null || true

echo "🗑️  删除所有Neo4j相关卷..."
docker volume rm looma_crm_neo4j_data looma_crm_neo4j_import looma_crm_neo4j_logs looma_crm_neo4j_plugins shared-infrastructure_neo4j_data shared-infrastructure_neo4j_import shared-infrastructure_neo4j_logs shared-infrastructure_neo4j_plugins 2>/dev/null || true

echo "🗑️  删除所有JobFirst相关网络..."
docker network rm jobfirst-network 2>/dev/null || true

echo "🧹 清理悬空镜像..."
docker image prune -f

echo "🧹 清理悬空容器..."
docker container prune -f

echo "🧹 清理悬空卷..."
docker volume prune -f

echo "🧹 清理悬空网络..."
docker network prune -f

echo "🧹 清理构建缓存..."
docker builder prune -f

echo ""
echo "✅ Docker环境清理完成！"
echo ""
echo "📊 清理结果:"
echo "   - 容器: $(docker ps -a --format 'table {{.Names}}' | grep -c jobfirst || echo 0) 个JobFirst容器"
echo "   - 镜像: $(docker images --format 'table {{.Repository}}' | grep -c jobfirst || echo 0) 个JobFirst镜像"
echo "   - 卷: $(docker volume ls --format 'table {{.Name}}' | grep -c jobfirst || echo 0) 个JobFirst卷"
echo "   - 网络: $(docker network ls --format 'table {{.Name}}' | grep -c jobfirst || echo 0) 个JobFirst网络"
echo ""
echo "🚀 现在可以启动干净的开发环境:"
echo "   ./dev-start.sh"
