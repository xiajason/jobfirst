#!/bin/bash

# API认证规则应用脚本
# 用于重新组织路由结构，明确区分公开API和需要认证的API

echo "🔐 开始应用API认证规则..."

# 备份当前文件
echo "📦 备份当前文件..."
cp backend/user/main.go backend/user/main.go.backup.$(date +%Y%m%d_%H%M%S)

echo "✅ 备份完成"

# 创建路由重构说明
cat > docs/ROUTE_REORGANIZATION_PLAN.md << 'EOF'
# 路由重构计划

## 当前问题
1. 路由组织混乱，公开API和需要认证的API混在一起
2. 缺乏明确的认证中间件应用
3. 白名单规则不清晰

## 重构方案

### 1. 白名单路由 (无需认证)
- `/health` - 健康检查
- `/metrics` - 监控指标
- `/swagger/*` - API文档

### 2. 公开API路由组 (无需认证)
- `/api/v2/auth/*` - 用户认证相关
- `/api/v2/jobs/*` - 职位展示相关
- `/api/v2/companies/*` - 企业展示相关
- `/api/v2/banners/*` - 轮播图相关

### 3. 需要认证的API路由组
- `/api/v2/user/*` - 用户个人中心
- `/api/v2/jobs/applications` - 职位申请相关
- `/api/v2/chat/*` - 聊天系统
- `/api/v2/points/*` - 积分系统
- `/api/v2/notifications/*` - 通知系统

### 4. 兼容性API (v1)
- 保持现有v1 API不变
- 逐步迁移到v2 API

## 实施步骤
1. 重新组织路由结构
2. 应用认证中间件
3. 测试API访问权限
4. 更新前端调用
EOF

echo "📝 创建路由重构计划完成"

# 创建认证测试脚本
cat > scripts/test-auth-rules.sh << 'EOF'
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
EOF

chmod +x scripts/test-auth-rules.sh

echo "🧪 创建认证测试脚本完成"

# 创建前端集成指南
cat > docs/FRONTEND_AUTH_INTEGRATION.md << 'EOF'
# 前端认证集成指南

## 认证头设置

### 方式1: Bearer Token
```javascript
headers: {
  'Authorization': 'Bearer ' + token,
  'API-Version': 'v2'
}
```

### 方式2: Access Token (兼容原有系统)
```javascript
headers: {
  'accessToken': token,
  'API-Version': 'v2'
}
```

## 请求拦截器示例

```javascript
// 请求拦截器
wx.addInterceptor('request', {
  invoke(args) {
    // 添加认证头
    if (wx.getStorageSync('token')) {
      args.header = {
        ...args.header,
        'Authorization': 'Bearer ' + wx.getStorageSync('token'),
        'API-Version': 'v2'
      }
    }
  },
  success(res) {
    // 处理401错误
    if (res.statusCode === 401) {
      wx.removeStorageSync('token')
      wx.navigateTo({
        url: '/pages/login/login'
      })
    }
  }
})
```

## API调用示例

### 公开API (无需认证)
```javascript
// 获取职位列表
wx.request({
  url: 'http://localhost:8080/api/v2/jobs/',
  method: 'GET',
  header: {
    'API-Version': 'v2'
  },
  success(res) {
    console.log('职位列表:', res.data)
  }
})
```

### 需要认证的API
```javascript
// 获取用户资料
wx.request({
  url: 'http://localhost:8080/api/v2/user/profile',
  method: 'GET',
  header: {
    'Authorization': 'Bearer ' + wx.getStorageSync('token'),
    'API-Version': 'v2'
  },
  success(res) {
    console.log('用户资料:', res.data)
  }
})
```
EOF

echo "📱 创建前端集成指南完成"

echo "🎉 API认证规则应用完成！"
echo ""
echo "📋 下一步操作："
echo "1. 查看 docs/ROUTE_REORGANIZATION_PLAN.md 了解重构计划"
echo "2. 运行 scripts/test-auth-rules.sh 测试认证规则"
echo "3. 查看 docs/FRONTEND_AUTH_INTEGRATION.md 了解前端集成"
echo "4. 手动更新 backend/user/main.go 中的路由结构"
echo ""
echo "⚠️  注意：需要手动更新路由代码，脚本只创建了文档和测试工具"
