#!/bin/bash

echo "🚀 启动JobFirst后端开发服务..."

# 检查基础设施是否运行
check_service() {
    local service=$1
    local port=$2
    
    if ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "❌ $service 未运行，请先启动基础设施"
        echo "   运行: ./scripts/start-infrastructure.sh"
        exit 1
    fi
}

# 检查关键服务
check_service "MySQL" 3306
check_service "Redis" 6379
check_service "Consul" 8500

# 加载环境变量
if [ -f ".env.dev" ]; then
    echo "📝 加载开发环境变量..."
    export $(cat .env.dev | xargs)
else
    echo "⚠️  .env.dev 文件不存在，使用默认配置"
fi

# 检查air是否安装
if ! command -v air &> /dev/null; then
    echo "❌ air未安装，请先运行: ./scripts/setup-dev-env.sh"
    exit 1
fi

# 创建临时目录
mkdir -p tmp

# 停止已运行的服务
echo "🛑 停止已运行的服务..."
pkill -f "air" || true
pkill -f "gateway" || true
pkill -f "user" || true
pkill -f "resume" || true
pkill -f "statistics" || true
pkill -f "storage" || true
pkill -f "points" || true

sleep 2

echo "🔧 启动后端服务..."

# 启动各个服务 (使用air热重载)
services=(
    "gateway:8080"
    "user:8081"
    "resume:8087"
    "statistics:8097"
    "storage:8088"
    "points:8086"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r service_name port <<< "$service_info"
    
    if [ -d "backend/$service_name" ]; then
        echo "启动 $service_name 服务 (端口: $port)..."
        
        # 创建air配置文件
        if [ ! -f "backend/$service_name/.air.toml" ]; then
            cat > "backend/$service_name/.air.toml" << EOF
root = "."
testdata_dir = "testdata"
tmp_dir = "tmp"

[build]
  args_bin = []
  bin = "./tmp/main"
  cmd = "go build -o ./tmp/main ."
  delay = 1000
  exclude_dir = ["assets", "tmp", "vendor", "testdata"]
  exclude_file = []
  exclude_regex = ["_test.go"]
  exclude_unchanged = false
  follow_symlink = false
  full_bin = ""
  include_dir = []
  include_ext = ["go", "tpl", "tmpl", "html"]
  include_file = []
  kill_delay = "0s"
  log = "build-errors.log"
  poll = false
  poll_interval = 0
  rerun = false
  rerun_delay = 500
  send_interrupt = false
  stop_on_root = false

[color]
  app = ""
  build = "yellow"
  main = "magenta"
  runner = "green"
  watcher = "cyan"

[log]
  main_only = false
  time = false

[misc]
  clean_on_exit = false

[screen]
  clear_on_rebuild = false
  keep_scroll = true
EOF
        fi
        
        # 启动服务
        cd "backend/$service_name"
        air > "../../tmp/${service_name}.log" 2>&1 &
        cd ../..
        
        echo "✅ $service_name 服务启动完成"
    else
        echo "⚠️  服务目录 backend/$service_name 不存在，跳过"
    fi
done

echo ""
echo "⏳ 等待服务启动..."
sleep 5

echo ""
echo "✅ 后端开发服务启动完成！"
echo ""
echo "📊 服务端口:"
echo "   API网关: http://localhost:8080"
echo "   用户服务: http://localhost:8081"
echo "   简历服务: http://localhost:8082"
echo "   统计服务: http://localhost:8085"
echo "   存储服务: http://localhost:8088"
echo "   积分服务: http://localhost:8083"
echo ""
echo "🔍 健康检查:"
echo "   网关健康检查: http://localhost:8080/health"
echo "   用户服务健康检查: http://localhost:8081/health"
echo "   简历服务健康检查: http://localhost:8082/health"
echo ""
echo "📋 常用命令:"
echo "   查看日志: tail -f tmp/[服务名].log"
echo "   停止服务: pkill -f air"
echo "   重启服务: 修改代码后会自动重启"
echo ""
echo "💡 提示:"
echo "   - 修改代码后会自动重新编译和重启"
echo "   - 日志文件保存在 tmp/ 目录下"
echo "   - 使用 Ctrl+C 停止所有服务"
