#!/bin/bash

echo "🔧 配置JobFirst开发环境..."

# 检查Go是否安装
if ! command -v go &> /dev/null; then
    echo "❌ Go未安装，请先安装Go"
    exit 1
fi

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

echo "📦 安装后端依赖..."

# 安装后端依赖
cd backend
for service in gateway user resume statistics storage points; do
    if [ -d "$service" ]; then
        echo "安装 $service 服务依赖..."
        cd $service
        go mod tidy
        go mod download
        cd ..
    else
        echo "⚠️  服务目录 $service 不存在，跳过"
    fi
done

# 返回项目根目录
cd ..

echo "📦 安装前端依赖..."

# 安装前端依赖
if [ -d "frontend/web" ]; then
    cd frontend/web
    npm install
    cd ../..
else
    echo "⚠️  前端目录 frontend/web 不存在，跳过"
fi

echo "🛠️  安装开发工具..."

# 安装air热重载工具
if ! command -v air &> /dev/null; then
    echo "安装air热重载工具..."
    go install github.com/cosmtrek/air@latest
else
    echo "✅ air已安装"
fi

# 创建开发环境变量文件
if [ ! -f ".env.dev" ]; then
    echo "📝 创建开发环境变量文件..."
    cat > .env.dev << EOF
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=jobfirst
DB_PASSWORD=jobfirst123
DB_NAME=jobfirst

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379

# Consul配置
CONSUL_HOST=localhost
CONSUL_PORT=8500

# 服务配置
GATEWAY_PORT=8080
USER_SERVICE_PORT=8081
RESUME_SERVICE_PORT=8082
STATISTICS_SERVICE_PORT=8085
STORAGE_SERVICE_PORT=8088
POINTS_SERVICE_PORT=8083

# 开发模式
ENV=development
DEBUG=true
EOF
    echo "✅ 创建 .env.dev 文件"
else
    echo "✅ .env.dev 文件已存在"
fi

# 创建VS Code配置目录
mkdir -p .vscode

# 创建VS Code调试配置
if [ ! -f ".vscode/launch.json" ]; then
    echo "📝 创建VS Code调试配置..."
    cat > .vscode/launch.json << EOF
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Gateway",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "\${workspaceFolder}/backend/gateway/main.go",
      "env": {
        "CONSUL_ADDRESS": "localhost:8500",
        "REDIS_ADDRESS": "localhost:6379"
      }
    },
    {
      "name": "Debug User Service",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "\${workspaceFolder}/backend/user/main.go",
      "env": {
        "CONSUL_ADDRESS": "localhost:8500",
        "REDIS_ADDRESS": "localhost:6379",
        "MYSQL_ADDRESS": "localhost:3306"
      }
    },
    {
      "name": "Debug Resume Service",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "\${workspaceFolder}/backend/resume/main.go",
      "env": {
        "CONSUL_ADDRESS": "localhost:8500",
        "REDIS_ADDRESS": "localhost:6379",
        "MYSQL_ADDRESS": "localhost:3306"
      }
    }
  ]
}
EOF
    echo "✅ 创建VS Code调试配置"
else
    echo "✅ VS Code调试配置已存在"
fi

echo ""
echo "✅ 开发环境配置完成！"
echo ""
echo "📋 下一步操作:"
echo "   1. 启动基础设施: ./scripts/start-infrastructure.sh"
echo "   2. 启动后端开发: ./scripts/start-backend-dev.sh"
echo "   3. 启动前端开发: ./scripts/start-frontend-dev.sh"
echo ""
echo "🔧 开发工具:"
echo "   - air: Go热重载工具"
echo "   - VS Code: 调试配置已创建"
echo "   - 环境变量: .env.dev 文件已创建"
