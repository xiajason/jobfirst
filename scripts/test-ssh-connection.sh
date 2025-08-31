#!/bin/bash

# 测试SSH连接脚本
echo "=== 测试SSH连接 ==="

# 检查环境变量
echo "检查环境变量..."
echo "TENCENT_STAGING_HOST: ${TENCENT_STAGING_HOST:-未设置}"
echo "TENCENT_USER: ${TENCENT_USER:-未设置}"
echo "TENCENT_SSH_KEY: ${TENCENT_SSH_KEY:0:50}..." # 只显示前50个字符

# 创建临时SSH密钥文件
echo "创建临时SSH密钥文件..."
mkdir -p ~/.ssh
echo "$TENCENT_SSH_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# 测试SSH连接
echo "测试SSH连接..."
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ~/.ssh/id_rsa ${TENCENT_USER}@${TENCENT_STAGING_HOST} "echo 'SSH连接成功!'"

# 清理
rm -f ~/.ssh/id_rsa

echo "=== SSH连接测试完成 ==="
