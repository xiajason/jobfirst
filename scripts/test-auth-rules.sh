#!/bin/bash

# API认证规则测试脚本

echo "🧪 开始测试API认证规则..."

BASE_URL="http://localhost:8080"

# 测试公开API (应该成功)
echo "✅ 测试公开API..."
curl -s -X GET "$BASE_URL/api/v2/jobs/" -H "API-Version: v2" | jq '.code' || echo "❌ 公开API测试失败"

# 测试需要认证的API (应该失败)
echo "❌ 测试需要认证的API (无token)..."
curl -s -X GET "$BASE_URL/api/v2/user/profile" -H "API-Version: v2" | jq '.code' || echo "✅ 认证检查正常"

# 测试需要认证的API (有token，应该成功)
echo "✅ 测试需要认证的API (有token)..."
curl -s -X GET "$BASE_URL/api/v2/user/profile" \
  -H "API-Version: v2" \
  -H "Authorization: Bearer test-token" | jq '.code' || echo "❌ 认证API测试失败"

echo "🎯 认证规则测试完成"
