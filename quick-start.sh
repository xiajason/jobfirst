#!/bin/bash

# JobFirst 快速启动脚本
# 一键启动开发环境

echo "🚀 JobFirst 开发环境快速启动"
echo "================================"

# 检查是否在正确的目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

# 启动开发环境
echo "📦 启动开发环境..."
./scripts/dev-start.sh start

echo ""
echo "✅ 开发环境启动完成！"
echo ""
echo "🌐 访问地址："
echo ""
echo "📋 正常运行的服务："
echo "   个人端服务: http://localhost:6001"
echo "   管理端服务: http://localhost:8003"
echo "   资源服务: http://localhost:9002"
echo "   开放API服务: http://localhost:9006"
echo "   Consul UI: http://localhost:8202"
echo "   Neo4j浏览器: http://localhost:8203"
echo "   MySQL: localhost:8200"
echo "   Redis: localhost:8201"
echo ""
echo "⚠️  需要恢复的服务："
echo "   API网关: http://localhost:8080 (无响应)"
echo "   用户服务: http://localhost:8081 (无响应)"
echo "   简历服务: http://localhost:8087 (无响应)"
echo "   积分服务: http://localhost:8086 (无响应)"
echo "   统计服务: http://localhost:8097 (无响应)"
echo "   存储服务: http://localhost:8088 (未启动)"
echo "   前端Web: http://localhost:3000 (未启动)"
echo ""
echo "📋 常用命令："
echo "   ./scripts/dev-start.sh status    # 查看服务状态"
echo "   ./scripts/dev-start.sh logs      # 查看日志"
echo "   ./scripts/dev-start.sh stop      # 停止所有服务"
echo "   ./scripts/dev-start.sh restart <service>  # 重启指定服务"
echo ""
echo "🔄 热加载已启用，修改代码后会自动重启服务"
echo ""
echo "💡 提示：如果核心服务无响应，请运行以下命令重启："
echo "   ./scripts/dev-start.sh restart gateway"
echo "   ./scripts/dev-start.sh restart user"
echo "   ./scripts/dev-start.sh restart resume"
echo "   ./scripts/dev-start.sh restart points"
echo "   ./scripts/dev-start.sh restart statistics"
echo "   ./scripts/dev-start.sh restart storage"
