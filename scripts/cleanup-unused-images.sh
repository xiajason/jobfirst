#!/bin/bash

echo "🧹 清理未使用的Docker镜像"
echo "========================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "📊 当前镜像使用情况分析..."
echo "=========================="

# 检查哪些镜像正在被使用
echo "🔍 检查正在使用的镜像..."
USED_IMAGES=$(docker ps -a --format "{{.Image}}" | sort | uniq)
echo "正在使用的镜像:"
echo "$USED_IMAGES" | while read image; do
    if [ ! -z "$image" ]; then
        echo "  - $image"
    fi
done

echo ""
echo "📋 清理建议:"
echo "============"

# JobFirst需要保留的镜像
KEEP_IMAGES=(
    "mysql:8.0"
    "redis:7-alpine"
    "consul:1.15"
    "nginx:alpine"
    "alpine:latest"
    "neo4j:5.15-community"
)

# 可以清理的镜像
CLEANUP_IMAGES=(
    "ollama/ollama:latest"
    "dpage/pgadmin4:latest"
    "postgres:15-alpine"
    "postgres:13"
    "python:3.12-slim"
    "memcached:1.6-alpine"
    "docker.elastic.co/kibana/kibana:8.11.0"
    "docker.elastic.co/elasticsearch/elasticsearch:8.11.0"
    "grafana/grafana:10.2.0"
    "grafana/grafana:10.1.0"
    "prom/prometheus:v2.47.0"
    "rediscommander/redis-commander:latest"
    "shared-infrastructure-health-checker:latest"
    "hello-world:latest"
)

echo -e "${GREEN}✅ 保留的镜像 (JobFirst需要):${NC}"
for image in "${KEEP_IMAGES[@]}"; do
    echo "  - $image"
done

echo ""
echo -e "${YELLOW}🗑️  可以清理的镜像:${NC}"
for image in "${CLEANUP_IMAGES[@]}"; do
    echo "  - $image"
done

echo ""
echo "📊 清理前镜像统计:"
echo "=================="
TOTAL_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | wc -l)
TOTAL_SIZE=$(docker system df --format "table" | grep "Images" | awk '{print $3}')
echo "  总镜像数: $TOTAL_IMAGES"
echo "  总大小: $TOTAL_SIZE"

echo ""
echo "⚠️  即将清理以下镜像:"
echo "====================="
for image in "${CLEANUP_IMAGES[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$image"; then
        SIZE=$(docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$image" | awk '{print $2}')
        echo "  - $image ($SIZE)"
    fi
done

echo ""
read -p "是否继续清理这些镜像？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ 清理操作已取消${NC}"
    exit 1
fi

echo ""
echo "🗑️  开始清理镜像..."
echo "=================="

# 清理指定的镜像
for image in "${CLEANUP_IMAGES[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$image"; then
        echo "删除镜像: $image"
        docker rmi -f "$image" 2>/dev/null || echo "  无法删除 $image (可能正在使用)"
    fi
done

echo ""
echo "🧹 清理未使用的镜像..."
echo "======================"

# 清理所有未使用的镜像
echo "清理所有未使用的镜像..."
docker image prune -a -f

echo ""
echo "🧹 清理构建缓存..."
echo "=================="

# 清理构建缓存
echo "清理构建缓存..."
docker builder prune -a -f

echo ""
echo "📊 清理后镜像统计:"
echo "=================="
TOTAL_IMAGES_AFTER=$(docker images --format "{{.Repository}}:{{.Tag}}" | wc -l)
TOTAL_SIZE_AFTER=$(docker system df --format "table" | grep "Images" | awk '{print $3}')
echo "  总镜像数: $TOTAL_IMAGES_AFTER"
echo "  总大小: $TOTAL_SIZE_AFTER"

echo ""
echo "📋 清理后的镜像列表:"
echo "===================="
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""
echo -e "${GREEN}✅ 镜像清理完成！${NC}"
echo ""
echo "💡 提示:"
echo "   - 只保留了JobFirst需要的基础镜像"
echo "   - 清理了所有第三方服务和监控工具"
echo "   - 释放了大量磁盘空间"
echo ""
echo "🚀 现在可以启动干净的JobFirst开发环境:"
echo "   ./dev-start.sh"
