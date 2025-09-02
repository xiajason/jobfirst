#!/bin/bash

# JobFirst 增强模式启动脚本
# 包含完整的认证中间件和CORS功能

set -e

echo "🚀 启动JobFirst增强模式..."
echo "📋 功能特性:"
echo "   ✅ JWT认证中间件"
echo "   ✅ CORS跨域支持"
echo "   ✅ API版本控制"
echo "   ✅ 服务发现"
echo "   ✅ 负载均衡"
echo "   ✅ 限流控制"
echo ""

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose down 2>/dev/null || true

# 构建增强网关
echo "🔨 构建增强网关..."
cd backend/gateway
docker build -f Dockerfile.complete -t jobfirst-enhanced-gateway .
cd ../..

# 启动增强模式
echo "🚀 启动增强模式服务..."
docker-compose -f docker-compose.enhanced.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 等待网关完全启动
echo "⏳ 等待网关完全启动..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ 网关已启动"
        break
    fi
    echo "等待网关启动... ($i/30)"
    sleep 2
done

# 测试网关功能
echo ""
echo "🧪 测试网关功能..."

# 测试健康检查
echo "🔍 测试健康检查..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ 健康检查通过"
else
    echo "❌ 健康检查失败"
    echo "响应: $HEALTH_RESPONSE"
fi

# 测试网关信息
echo "🔍 测试网关信息..."
INFO_RESPONSE=$(curl -s http://localhost:8080/info)
if echo "$INFO_RESPONSE" | grep -q "jobfirst-gateway"; then
    echo "✅ 网关信息正常"
else
    echo "❌ 网关信息异常"
    echo "响应: $INFO_RESPONSE"
fi

# 测试CORS预检请求
echo "🔍 测试CORS预检请求..."
CORS_RESPONSE=$(curl -s -X OPTIONS http://localhost:8080/api/v1/user/profile \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: GET" \
    -H "Access-Control-Request-Headers: Authorization" \
    -w "%{http_code}")
if [ "$CORS_RESPONSE" = "204" ]; then
    echo "✅ CORS预检请求正常"
else
    echo "❌ CORS预检请求异常: $CORS_RESPONSE"
fi

# 测试认证中间件
echo "🔍 测试认证中间件..."
AUTH_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:8080/api/v1/user/profile)
if [ "$AUTH_RESPONSE" = "401" ]; then
    echo "✅ 认证中间件正常工作 (返回401)"
else
    echo "❌ 认证中间件异常: $AUTH_RESPONSE"
fi

# 测试无效token
echo "🔍 测试无效token..."
INVALID_TOKEN_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:8080/api/v1/user/profile \
    -H "Authorization: Bearer invalid_token")
if [ "$INVALID_TOKEN_RESPONSE" = "401" ]; then
    echo "✅ 无效token处理正常 (返回401)"
else
    echo "❌ 无效token处理异常: $INVALID_TOKEN_RESPONSE"
fi

# 测试管理员权限
echo "🔍 测试管理员权限..."
ADMIN_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:8080/admin/users \
    -H "Authorization: Bearer invalid_token")
if [ "$ADMIN_RESPONSE" = "401" ] || [ "$ADMIN_RESPONSE" = "403" ]; then
    echo "✅ 管理员权限检查正常"
else
    echo "❌ 管理员权限检查异常: $ADMIN_RESPONSE"
fi

# 显示服务信息
echo ""
echo "📊 服务信息:"
echo "   🌐 网关地址: http://localhost:8080"
echo "   📋 Consul UI: http://localhost:8202"
echo "   🗄️  MySQL: localhost:8200"
echo "   🔴 Redis: localhost:8201"
echo "   🐘 PostgreSQL: localhost:8203"
echo "   🕸️  Neo4j: http://localhost:8204"

# 显示API端点
echo ""
echo "🔗 API端点:"
echo "   📊 健康检查: http://localhost:8080/health"
echo "   ℹ️  网关信息: http://localhost:8080/info"
echo "   📈 指标监控: http://localhost:8080/metrics"
echo "   🔐 认证API: http://localhost:8080/api/v1/user/*"
echo "   📄 简历API: http://localhost:8080/api/v1/resume/*"
echo "   🎯 积分API: http://localhost:8080/api/v1/points/*"
echo "   📊 统计API: http://localhost:8080/api/v1/statistics/*"
echo "   🗄️  存储API: http://localhost:8080/api/v1/storage/*"
echo "   🤖 AI API: http://localhost:8080/api/v1/ai/*"

echo ""
echo "🎉 JobFirst增强模式启动完成！"
echo ""
echo "💡 提示:"
echo "   - 使用 'docker-compose -f docker-compose.enhanced.yml logs -f' 查看日志"
echo "   - 使用 'docker-compose -f docker-compose.enhanced.yml down' 停止服务"
echo "   - 运行 'node test_auth_cors.js' 进行完整功能测试"
echo ""
