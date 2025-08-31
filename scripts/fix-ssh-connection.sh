#!/bin/bash

echo "=== 修复SSH连接问题 ==="

# 检查当前状态
echo "1. 检查服务器连通性..."
nc -zv 101.33.251.158 22 && echo "✅ SSH端口开放" || echo "❌ SSH端口关闭"

echo "2. 检查私钥文件..."
if [ -f ~/.ssh/tencent_deploy_key ]; then
    echo "✅ 私钥文件存在"
    ls -la ~/.ssh/tencent_deploy_key
else
    echo "❌ 私钥文件不存在"
    exit 1
fi

echo "3. 显示公钥内容..."
echo "请将以下公钥添加到服务器的 ~/.ssh/authorized_keys 文件中："
echo "=========================================="
cat ~/.ssh/tencent_deploy_key.pub
echo "=========================================="

echo "4. 测试SSH连接..."
ssh -i ~/.ssh/tencent_deploy_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@101.33.251.158 "echo 'SSH连接成功!'" 2>/dev/null && echo "✅ SSH连接成功" || echo "❌ SSH连接失败"

echo "=== 修复步骤 ==="
echo "如果SSH连接失败，请执行以下步骤："
echo "1. 登录腾讯云控制台"
echo "2. 找到服务器实例"
echo "3. 使用控制台或VNC连接到服务器"
echo "4. 将上面的公钥添加到 ~/.ssh/authorized_keys 文件中"
echo "5. 确保 ~/.ssh 目录权限为 700"
echo "6. 确保 ~/.ssh/authorized_keys 文件权限为 600"

echo "=== 修复完成 ==="
