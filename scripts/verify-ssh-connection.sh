#!/bin/bash

echo "=== SSH连接验证脚本 ==="

# 检查私钥文件
echo "1. 检查私钥文件..."
if [ -f ~/.ssh/tencent_deploy_key ]; then
    echo "✅ 私钥文件存在: ~/.ssh/tencent_deploy_key"
    ls -la ~/.ssh/tencent_deploy_key
else
    echo "❌ 私钥文件不存在"
    exit 1
fi

# 显示公钥内容
echo "2. 公钥内容:"
echo "=========================================="
cat ~/.ssh/tencent_deploy_key.pub
echo "=========================================="

# 测试SSH连接
echo "3. 测试SSH连接..."
echo "尝试连接 ubuntu@101.33.251.158..."

# 使用详细模式测试SSH连接
ssh -i ~/.ssh/tencent_deploy_key -v -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@101.33.251.158 "echo 'SSH连接成功!'" 2>&1 | head -20

echo "4. 检查服务器连通性..."
nc -zv 101.33.251.158 22 && echo "✅ SSH端口开放" || echo "❌ SSH端口关闭"

echo "=== 解决方案 ==="
echo "如果SSH连接失败，请执行以下步骤："
echo "1. 登录腾讯云控制台"
echo "2. 连接到服务器"
echo "3. 将上面的公钥添加到 ~/.ssh/authorized_keys 文件中："
echo "   echo '$(cat ~/.ssh/tencent_deploy_key.pub)' >> ~/.ssh/authorized_keys"
echo "4. 确保文件权限正确："
echo "   chmod 700 ~/.ssh"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo "5. 重启SSH服务："
echo "   sudo systemctl restart ssh"
