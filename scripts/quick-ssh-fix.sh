#!/bin/bash

echo "=== 快速SSH连接修复 ==="

# 方案1: 尝试使用root用户连接
echo "1. 测试root用户SSH连接..."
ssh -i ~/.ssh/tencent_deploy_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@101.33.251.158 "echo 'root用户SSH连接成功!'" 2>/dev/null && {
    echo "✅ root用户连接成功！"
    echo "现在可以重新触发CI/CD流水线"
    exit 0
} || echo "❌ root用户连接失败"

# 方案2: 尝试使用ubuntu用户连接
echo "2. 测试ubuntu用户SSH连接..."
ssh -i ~/.ssh/tencent_deploy_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@101.33.251.158 "echo 'ubuntu用户SSH连接成功!'" 2>/dev/null && {
    echo "✅ ubuntu用户连接成功！"
    echo "需要更新GitHub Secrets中的TENCENT_USER为ubuntu"
    exit 0
} || echo "❌ ubuntu用户连接失败"

echo "3. 检查服务器连通性..."
nc -zv 101.33.251.158 22 && echo "✅ SSH端口开放" || echo "❌ SSH端口关闭"

echo "=== 修复建议 ==="
echo "请按照以下步骤操作："
echo "1. 登录腾讯云控制台"
echo "2. 选择其中一个连接配置（建议选择root用户）"
echo "3. 连接到服务器"
echo "4. 将公钥添加到对应用户的authorized_keys文件"
echo "5. 重新测试SSH连接"
echo "6. 触发CI/CD流水线"

echo "=== 公钥内容 ==="
cat ~/.ssh/tencent_deploy_key.pub
