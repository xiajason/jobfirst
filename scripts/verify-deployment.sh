#!/bin/bash

# 部署验证脚本
echo "=== JobFirst 测试环境部署验证 ==="

# 检查环境变量
STAGING_HOST="${TENCENT_STAGING_HOST:-101.33.251.158}"
echo "测试环境主机: $STAGING_HOST"

# 等待服务启动
echo "等待服务启动..."
sleep 30

# 检查端口连通性
echo "检查端口连通性..."

# 检查8000端口（API网关）
echo "检查API网关端口 8000..."
if nc -z -w5 $STAGING_HOST 8000; then
    echo "✅ API网关端口 8000 可访问"
else
    echo "❌ API网关端口 8000 不可访问"
fi

# 检查8210端口（共享基础设施）
echo "检查共享基础设施端口 8210..."
if nc -z -w5 $STAGING_HOST 8210; then
    echo "✅ 共享基础设施端口 8210 可访问"
else
    echo "❌ 共享基础设施端口 8210 不可访问"
fi

# 检查3306端口（MySQL）
echo "检查MySQL端口 3306..."
if nc -z -w5 $STAGING_HOST 3306; then
    echo "✅ MySQL端口 3306 可访问"
else
    echo "❌ MySQL端口 3306 不可访问"
fi

# 检查6379端口（Redis）
echo "检查Redis端口 6379..."
if nc -z -w5 $STAGING_HOST 6379; then
    echo "✅ Redis端口 6379 可访问"
else
    echo "❌ Redis端口 6379 不可访问"
fi

# 测试HTTP健康检查
echo "测试HTTP健康检查..."

# 测试API网关健康检查
echo "测试API网关健康检查..."
if curl -f --connect-timeout 10 http://$STAGING_HOST:8000/health 2>/dev/null; then
    echo "✅ API网关健康检查通过"
else
    echo "❌ API网关健康检查失败"
fi

# 测试共享基础设施健康检查
echo "测试共享基础设施健康检查..."
if curl -f --connect-timeout 10 http://$STAGING_HOST:8210/health 2>/dev/null; then
    echo "✅ 共享基础设施健康检查通过"
else
    echo "❌ 共享基础设施健康检查失败"
fi

echo "=== 部署验证完成 ==="
