#!/bin/bash

# SSH连接测试脚本
echo "=== SSH连接测试 ==="

# 测试SSH连接
echo "测试SSH连接到腾讯云服务器..."
ssh -i ~/.ssh/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@101.33.251.158 "echo 'SSH连接成功 - 服务器信息:' && hostname && whoami && date"

if [ $? -eq 0 ]; then
    echo "✅ SSH连接测试成功"
else
    echo "❌ SSH连接测试失败"
    exit 1
fi

echo "=== 测试完成 ==="
