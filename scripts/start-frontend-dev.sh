#!/bin/bash

echo "🚀 启动JobFirst前端开发服务..."

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装，请先安装Node.js"
    exit 1
fi

# 检查npm是否安装
if ! command -v npm &> /dev/null; then
    echo "❌ npm未安装，请先安装npm"
    exit 1
fi

# 检查前端目录是否存在
if [ ! -d "frontend/web" ]; then
    echo "❌ 前端目录 frontend/web 不存在"
    exit 1
fi

# 检查package.json是否存在
if [ ! -f "frontend/web/package.json" ]; then
    echo "❌ package.json 文件不存在"
    exit 1
fi

# 检查node_modules是否存在
if [ ! -d "frontend/web/node_modules" ]; then
    echo "📦 安装前端依赖..."
    cd frontend/web
    npm install
    cd ../..
else
    echo "✅ 前端依赖已安装"
fi

# 检查端口占用
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  端口 3000 已被占用，前端服务可能无法启动"
    echo "   可以使用以下命令查看占用进程："
    echo "   lsof -i :3000"
    read -p "是否继续启动？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "🔧 启动前端开发服务器..."

# 进入前端目录
cd frontend/web

# 设置环境变量
export NODE_ENV=development
export NEXT_PUBLIC_API_URL=http://localhost:8080

echo "🌐 前端开发服务器启动中..."
echo "   访问地址: http://localhost:3000"
echo "   API地址: http://localhost:8080"
echo ""
echo "💡 提示:"
echo "   - 修改代码后会自动重新加载"
echo "   - 使用 Ctrl+C 停止服务"
echo ""

# 启动Next.js开发服务器
npm run dev
