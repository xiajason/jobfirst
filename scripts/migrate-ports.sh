#!/bin/bash

echo "🔄 JobFirst 端口迁移脚本"
echo "========================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查端口函数
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # 端口被占用
    else
        return 1  # 端口可用
    fi
}

echo "📊 当前端口冲突分析..."
echo "========================"

# 检查冲突的端口
CONFLICT_PORTS=()
if check_port 8000; then
    CONFLICT_PORTS+=("8000:talent_shared_kong")
fi
if check_port 8001; then
    CONFLICT_PORTS+=("8001:talent_shared_ai_model_manager")
fi
if check_port 8002; then
    CONFLICT_PORTS+=("8002:talent_shared_data_sync")
fi

if [ ${#CONFLICT_PORTS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ 没有发现端口冲突${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠️  发现端口冲突:${NC}"
for conflict in "${CONFLICT_PORTS[@]}"; do
    IFS=':' read -r port service <<< "$conflict"
    echo -e "${RED}   端口 $port 被 $service 占用${NC}"
done

echo ""
echo "🔄 开始端口迁移..."
echo "=================="

# 确认迁移操作
echo -e "${YELLOW}⚠️  即将进行以下操作:${NC}"
echo "   1. 停止所有JobFirst相关容器"
echo "   2. 停止冲突的第三方服务"
echo "   3. 更新Docker Compose配置"
echo "   4. 使用新的端口分配方案启动服务"
echo ""
read -p "是否继续迁移？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ 迁移操作已取消${NC}"
    exit 1
fi

echo ""
echo "🛑 第一步：停止现有服务..."
echo "=========================="

# 停止JobFirst服务
echo "停止JobFirst服务..."
docker-compose down 2>/dev/null || true

# 停止冲突的第三方服务
echo "停止冲突的第三方服务..."
docker stop talent_shared_kong talent_shared_ai_model_manager talent_shared_data_sync 2>/dev/null || true

echo -e "${GREEN}✅ 服务停止完成${NC}"

echo ""
echo "📝 第二步：创建新的Docker Compose配置..."
echo "======================================"

# 创建新的docker-compose.dev.yml
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  # 基础设施服务
  mysql:
    image: mysql:8.0
    container_name: jobfirst-mysql-dev
    ports:
      - "8200:3306"
    environment:
      MYSQL_ROOT_PASSWORD: jobfirst123
      MYSQL_DATABASE: jobfirst
      MYSQL_USER: jobfirst
      MYSQL_PASSWORD: jobfirst123
    volumes:
      - mysql_dev_data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    command: --default-authentication-plugin=mysql_native_password
    networks:
      - jobfirst-dev-network

  redis:
    image: redis:7-alpine
    container_name: jobfirst-redis-dev
    ports:
      - "8201:6379"
    volumes:
      - redis_dev_data:/data
    command: redis-server --appendonly yes
    networks:
      - jobfirst-dev-network

  consul:
    image: consul:1.15
    container_name: jobfirst-consul-dev
    ports:
      - "8202:8500"
      - "8206:8600/udp"
    volumes:
      - consul_dev_data:/consul/data
    command: consul agent -server -bootstrap-expect=1 -ui -client=0.0.0.0 -data-dir=/consul/data
    networks:
      - jobfirst-dev-network

  neo4j:
    image: neo4j:5.15-community
    container_name: jobfirst-neo4j-dev
    ports:
      - "8203:7474"
      - "8204:7687"
    environment:
      NEO4J_AUTH: neo4j/jobfirst123
      NEO4J_PLUGINS: '["apoc", "graph-data-science"]'
    volumes:
      - neo4j_dev_data:/data
      - neo4j_dev_logs:/logs
      - neo4j_dev_import:/var/lib/neo4j/import
      - neo4j_dev_plugins:/plugins
    networks:
      - jobfirst-dev-network

volumes:
  mysql_dev_data:
  redis_dev_data:
  consul_dev_data:
  neo4j_dev_data:
  neo4j_dev_logs:
  neo4j_dev_import:
  neo4j_dev_plugins:

networks:
  jobfirst-dev-network:
    driver: bridge
EOF

echo -e "${GREEN}✅ 新的Docker Compose配置已创建${NC}"

echo ""
echo "🔧 第三步：更新服务配置..."
echo "=========================="

# 更新网关配置
if [ -f "backend/gateway/config.yaml" ]; then
    echo "更新网关配置..."
    sed -i '' 's/port: 8080/port: 8000/' backend/gateway/config.yaml
    sed -i '' 's/address: "localhost:8500"/address: "consul:8500"/' backend/gateway/config.yaml
    sed -i '' 's/address: "localhost:6379"/address: "redis:6379"/' backend/gateway/config.yaml
fi

# 更新微服务配置
services=("user" "resume" "points" "statistics" "storage")
ports=("8001" "8002" "8003" "8004" "8005")

for i in "${!services[@]}"; do
    service=${services[$i]}
    port=${ports[$i]}
    
    if [ -f "backend/$service/config.yaml" ]; then
        echo "更新 $service 服务配置..."
        sed -i '' "s/port: [0-9]*/port: $port/" backend/$service/config.yaml
        sed -i '' 's/address: "localhost:8500"/address: "consul:8500"/' backend/$service/config.yaml
        sed -i '' 's/address: "localhost:6379"/address: "redis:6379"/' backend/$service/config.yaml
        sed -i '' 's/address: "localhost:3306"/address: "mysql:3306"/' backend/$service/config.yaml
    fi
done

echo -e "${GREEN}✅ 服务配置更新完成${NC}"

echo ""
echo "🚀 第四步：启动新的基础设施服务..."
echo "=================================="

# 启动基础设施服务
docker-compose -f docker-compose.dev.yml up -d mysql redis consul neo4j

echo "⏳ 等待基础设施服务启动..."
sleep 15

# 检查服务状态
echo "📊 基础设施服务状态:"
docker-compose -f docker-compose.dev.yml ps

echo ""
echo -e "${GREEN}✅ 端口迁移完成！${NC}"
echo ""
echo "🌐 新的访问地址:"
echo "=================="
echo "   API网关: http://localhost:8000"
echo "   用户服务: http://localhost:8001"
echo "   简历服务: http://localhost:8002"
echo "   积分服务: http://localhost:8003"
echo "   统计服务: http://localhost:8004"
echo "   存储服务: http://localhost:8005"
echo "   前端Web: http://localhost:8006"
echo "   Consul管理: http://localhost:8202"
echo "   Neo4j浏览器: http://localhost:8203"
echo "   MySQL: localhost:8200"
echo "   Redis: localhost:8201"
echo ""
echo "📋 下一步操作:"
echo "   1. 启动后端开发服务: ./scripts/start-backend-dev.sh"
echo "   2. 启动前端开发服务: ./scripts/start-frontend-dev.sh"
echo "   3. 或者一键启动: ./dev-start.sh"
echo ""
echo "🔧 常用命令:"
echo "   - 查看服务状态: docker-compose -f docker-compose.dev.yml ps"
echo "   - 查看日志: docker-compose -f docker-compose.dev.yml logs -f [服务名]"
echo "   - 停止服务: docker-compose -f docker-compose.dev.yml down"
