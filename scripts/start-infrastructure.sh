#!/bin/bash

echo "🚀 启动JobFirst开发基础设施..."

# 检查Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 检查docker-compose是否可用
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose未安装，请先安装docker-compose"
    exit 1
fi

# 检查端口占用
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  端口 $port 已被占用，$service 可能无法启动"
        echo "   可以使用以下命令查看占用进程："
        echo "   lsof -i :$port"
        read -p "是否继续启动？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检查关键端口
check_port 3306 "MySQL"
check_port 6379 "Redis"
check_port 8500 "Consul"

echo "🔧 启动基础设施服务..."

# 启动基础设施服务
docker-compose -f docker-compose.dev.yml up -d mysql redis consul

echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 基础设施状态:"
docker-compose -f docker-compose.dev.yml ps

echo ""
echo "✅ 基础设施启动完成！"
echo ""
echo "🌐 访问地址:"
echo "   Consul管理界面: http://localhost:8500"
echo "   MySQL: localhost:3306"
echo "   Redis: localhost:6379"
echo ""
echo "📋 常用命令:"
echo "   查看日志: docker-compose -f docker-compose.dev.yml logs -f [服务名]"
echo "   停止服务: docker-compose -f docker-compose.dev.yml down"
echo "   重启服务: docker-compose -f docker-compose.dev.yml restart [服务名]"
echo "   查看状态: docker-compose -f docker-compose.dev.yml ps"
