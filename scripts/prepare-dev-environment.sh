#!/bin/bash

echo "🏠 JobFirst开发环境准备脚本"
echo "============================"

echo "📊 第一步：导出重要数据..."

# 检查是否有Neo4j容器
if docker ps -a --format "table {{.Names}}" | grep -q "neo4j"; then
    echo "🔍 发现Neo4j容器，开始导出数据..."
    ./scripts/export-neo4j-data.sh
else
    echo "✅ 未发现Neo4j容器，跳过数据导出"
fi

echo ""
echo "🧹 第二步：清理Docker环境..."

# 确认清理操作
echo "⚠️  即将清理所有Docker容器、镜像、卷和网络"
echo "   这将释放大量磁盘空间并清理环境"
echo ""
read -p "是否继续清理？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 清理操作已取消"
    echo "💡 您可以稍后手动运行: ./scripts/cleanup-docker.sh"
    exit 1
fi

# 执行清理
./scripts/cleanup-docker.sh

echo ""
echo "🔧 第三步：配置开发环境..."

# 配置开发环境
./scripts/setup-dev-env.sh

echo ""
echo "✅ 开发环境准备完成！"
echo ""
echo "📊 准备结果:"
echo "   ✅ 重要数据已导出到 database_exports/ 目录"
echo "   ✅ Docker环境已清理"
echo "   ✅ 开发环境已配置"
echo ""
echo "🚀 现在可以启动开发环境:"
echo "   ./dev-start.sh"
echo ""
echo "📋 或者分步启动:"
echo "   1. 启动基础设施: ./scripts/start-infrastructure.sh"
echo "   2. 启动后端开发: ./scripts/start-backend-dev.sh"
echo "   3. 启动前端开发: ./scripts/start-frontend-dev.sh"
