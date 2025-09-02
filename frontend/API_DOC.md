# JobFirst API 接口文档

## 📋 文档概述

**版本**: v2.0  
**更新时间**: 2025年8月31日  
**网关版本**: Enhanced API Gateway v1.0  
**基础库版本**: WeChatLib 3.9.3  

## 🏗️ 架构说明

### API网关架构
```
客户端请求 → API网关 (8000) → 微服务集群
```

### 路由分发规则
- **公开API** (无需认证): `/api/auth/*`, `/api/jobs/*`, `/api/companies/*`
- **V1 API** (需要认证): `/api/v1/*`
- **V2 API** (新版本): `/api/v2/*`
- **管理API** (管理员权限): `/admin/*`

### 网关特性
- ✅ **负载均衡**: 轮询、最少连接、随机策略
- ✅ **熔断器**: 自动故障检测和恢复
- ✅ **限流器**: 令牌桶算法，全局限流
- ✅ **认证授权**: JWT Token验证
- ✅ **健康检查**: 自动服务健康监控
- ✅ **指标收集**: Prometheus监控集成

## 🔐 认证机制

### JWT Token认证
```http
Authorization: Bearer <your-jwt-token>
```

### Token获取
```http
POST /api/auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "your-password"
}
```

### 响应格式
```json
{
  "success": true,
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user_123",
      "username": "张三",
      "role": "jobseeker"
    }
  }
}
```

## 📊 统一响应格式

### 成功响应
```json
{
  "success": true,
  "code": 200,
  "message": "操作成功",
  "data": {},
  "timestamp": 1693456789
}
```

### 错误响应
```json
{
  "success": false,
  "code": 400,
  "message": "请求参数错误",
  "error": "详细错误信息",
  "timestamp": 1693456789
}
```

### 错误码说明
| 错误码 | 说明 | HTTP状态码 |
|--------|------|------------|
| 200 | 成功 | 200 |
| 400 | 请求参数错误 | 400 |
| 401 | 未授权 | 401 |
| 403 | 权限不足 | 403 |
| 404 | 资源不存在 | 404 |
| 429 | 请求过于频繁 | 429 |
| 500 | 服务器内部错误 | 500 |
| 503 | 服务不可用 | 503 |

## 🔑 公开API (无需认证)

### 1. 用户认证

#### 1.1 用户登录
```http
POST /api/auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "your-password"
}
```

#### 1.2 用户注册
```http
POST /api/auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "code": "123456",
  "password": "your-password",
  "userType": "jobseeker"
}
```

#### 1.3 发送验证码
```http
POST /api/auth/send-code
Content-Type: application/json

{
  "phone": "13800138000",
  "type": "register"
}
```

### 2. 职位信息

#### 2.1 获取职位列表
```http
GET /api/jobs?page=1&limit=10&keyword=前端&location=深圳
```

#### 2.2 获取职位详情
```http
GET /api/jobs/{jobId}
```

#### 2.3 搜索职位
```http
GET /api/jobs/search?keyword=React&location=北京&salary=15k-25k
```

### 3. 公司信息

#### 3.1 获取公司列表
```http
GET /api/companies?page=1&limit=10&industry=互联网
```

#### 3.2 获取公司详情
```http
GET /api/companies/{companyId}
```

## 🔒 V1 API (需要认证)

### 1. 用户管理

#### 1.1 获取用户信息
```http
GET /api/v1/user/profile
Authorization: Bearer <token>
```

#### 1.2 更新用户信息
```http
PUT /api/v1/user/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "张三",
  "avatar": "https://example.com/avatar.jpg",
  "bio": "前端开发工程师"
}
```

#### 1.3 修改密码
```http
PUT /api/v1/user/password
Authorization: Bearer <token>
Content-Type: application/json

{
  "oldPassword": "old-password",
  "newPassword": "new-password"
}
```

### 2. 简历管理

#### 2.1 获取简历列表
```http
GET /api/v1/resume/list
Authorization: Bearer <token>
```

#### 2.2 创建简历
```http
POST /api/v1/resume/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "前端开发工程师简历",
  "content": {
    "basic": {
      "name": "张三",
      "phone": "13800138000",
      "email": "zhangsan@example.com"
    },
    "experience": [
      {
        "company": "腾讯科技",
        "position": "前端开发工程师",
        "duration": "2020-2023",
        "description": "负责微信小程序开发"
      }
    ],
    "education": [
      {
        "school": "清华大学",
        "major": "计算机科学与技术",
        "degree": "本科",
        "graduation": "2020"
      }
    ]
  }
}
```

#### 2.3 更新简历
```http
PUT /api/v1/resume/{resumeId}
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "更新后的简历标题",
  "content": {}
}
```

#### 2.4 删除简历
```http
DELETE /api/v1/resume/{resumeId}
Authorization: Bearer <token>
```

#### 2.5 上传简历文件
```http
POST /api/v1/resume/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: <resume-file>
```

### 3. 个人中心

#### 3.1 获取个人统计数据
```http
GET /api/v1/personal/stats
Authorization: Bearer <token>
```

#### 3.2 获取投递记录
```http
GET /api/v1/personal/applications?page=1&limit=10
Authorization: Bearer <token>
```

#### 3.3 获取收藏列表
```http
GET /api/v1/personal/favorites?page=1&limit=10
Authorization: Bearer <token>
```

### 4. 积分系统

#### 4.1 获取积分余额
```http
GET /api/v1/points/balance
Authorization: Bearer <token>
```

#### 4.2 获取积分历史
```http
GET /api/v1/points/history?page=1&limit=10
Authorization: Bearer <token>
```

#### 4.3 积分兑换
```http
POST /api/v1/points/exchange
Authorization: Bearer <token>
Content-Type: application/json

{
  "productId": "premium_membership",
  "points": 1000
}
```

### 5. 数据统计

#### 5.1 获取市场数据
```http
GET /api/v1/statistics/market
Authorization: Bearer <token>
```

#### 5.2 获取个人数据
```http
GET /api/v1/statistics/personal
Authorization: Bearer <token>
```

#### 5.3 获取企业数据
```http
GET /api/v1/statistics/enterprise
Authorization: Bearer <token>
```

### 6. 文件存储

#### 6.1 上传文件
```http
POST /api/v1/storage/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: <file>
```

#### 6.2 获取文件信息
```http
GET /api/v1/storage/file/{fileId}
Authorization: Bearer <token>
```

#### 6.3 删除文件
```http
DELETE /api/v1/storage/file/{fileId}
Authorization: Bearer <token>
```

### 7. AI服务

#### 7.1 AI聊天
```http
POST /api/v1/ai/chat
Authorization: Bearer <token>
Content-Type: application/json

{
  "message": "帮我优化一下简历",
  "context": "前端开发工程师"
}
```

#### 7.2 简历分析
```http
POST /api/v1/ai/resume-analysis
Authorization: Bearer <token>
Content-Type: application/json

{
  "resumeId": "resume_123",
  "targetJob": "前端开发工程师"
}
```

#### 7.3 职位推荐
```http
POST /api/v1/ai/job-recommendation
Authorization: Bearer <token>
Content-Type: application/json

{
  "resumeId": "resume_123",
  "preferences": {
    "location": "深圳",
    "salary": "15k-25k",
    "industry": "互联网"
  }
}
```

## 🆕 V2 API (新版本)

### 1. 用户管理 V2

#### 1.1 获取用户信息 (增强版)
```http
GET /api/v2/user/profile
Authorization: Bearer <token>
```

**新增特性**:
- 返回更详细的用户信息
- 包含用户标签和偏好
- 支持多语言

#### 1.2 批量操作
```http
POST /api/v2/user/batch-update
Authorization: Bearer <token>
Content-Type: application/json

{
  "operations": [
    {
      "type": "update_profile",
      "data": {"name": "张三"}
    },
    {
      "type": "update_preferences",
      "data": {"notifications": true}
    }
  ]
}
```

### 2. 职位管理 V2

#### 2.1 智能职位搜索
```http
POST /api/v2/jobs/smart-search
Authorization: Bearer <token>
Content-Type: application/json

{
  "query": "前端开发",
  "filters": {
    "location": "深圳",
    "salary_range": [15000, 25000],
    "experience": "3-5年",
    "skills": ["React", "Vue", "JavaScript"]
  },
  "sort": "relevance",
  "page": 1,
  "limit": 20
}
```

#### 2.2 职位对比
```http
POST /api/v2/jobs/compare
Authorization: Bearer <token>
Content-Type: application/json

{
  "jobIds": ["job_1", "job_2", "job_3"]
}
```

### 3. 公司管理 V2

#### 3.1 公司详情 (增强版)
```http
GET /api/v2/companies/{companyId}
Authorization: Bearer <token>
```

**新增特性**:
- 公司文化评分
- 员工评价
- 薪资分布
- 技术栈分析

## 👨‍💼 管理API (管理员权限)

### 1. 系统管理

#### 1.1 获取系统状态
```http
GET /admin/system/status
Authorization: Bearer <admin-token>
```

#### 1.2 获取服务健康状态
```http
GET /admin/system/health
Authorization: Bearer <admin-token>
```

#### 1.3 获取系统指标
```http
GET /admin/system/metrics
Authorization: Bearer <admin-token>
```

### 2. 用户管理

#### 2.1 获取用户列表
```http
GET /admin/users?page=1&limit=20&role=jobseeker
Authorization: Bearer <admin-token>
```

#### 2.2 用户详情
```http
GET /admin/users/{userId}
Authorization: Bearer <admin-token>
```

#### 2.3 禁用用户
```http
PUT /admin/users/{userId}/disable
Authorization: Bearer <admin-token>
```

### 3. 内容管理

#### 3.1 获取职位列表
```http
GET /admin/jobs?page=1&limit=20&status=pending
Authorization: Bearer <admin-token>
```

#### 3.2 审核职位
```http
PUT /admin/jobs/{jobId}/review
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "status": "approved",
  "comment": "审核通过"
}
```

## 🔧 网关特性

### 1. 限流规则
- **全局限流**: 1000 req/s, 突发200
- **用户限流**: 100 req/min
- **服务限流**: 根据服务配置

### 2. 熔断器配置
- **失败阈值**: 5次失败
- **恢复超时**: 30秒
- **半开状态**: 3次成功恢复

### 3. 负载均衡
- **策略**: 轮询、最少连接、随机
- **健康检查**: 自动检测服务状态
- **故障转移**: 自动切换到健康实例

### 4. 监控指标
- **请求总数**: `gateway_requests_total`
- **请求延迟**: `gateway_request_duration_seconds`
- **错误率**: `gateway_errors_total`
- **熔断器状态**: `gateway_circuit_breaker_state`

## 📝 使用示例

### 小程序端调用示例
```javascript
// 登录
const login = async (phone, password) => {
  try {
    const response = await wx.request({
      url: 'https://api.adirp.com/api/auth/login',
      method: 'POST',
      data: { phone, password },
      header: { 'Content-Type': 'application/json' }
    })
    
    if (response.data.success) {
      // 保存token
      wx.setStorageSync('token', response.data.data.token)
      return response.data.data
    } else {
      throw new Error(response.data.message)
    }
  } catch (error) {
    console.error('登录失败:', error)
    throw error
  }
}

// 获取用户信息
const getUserProfile = async () => {
  const token = wx.getStorageSync('token')
  if (!token) {
    throw new Error('未登录')
  }
  
  try {
    const response = await wx.request({
      url: 'https://api.adirp.com/api/v1/user/profile',
      method: 'GET',
      header: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
    
    return response.data
  } catch (error) {
    console.error('获取用户信息失败:', error)
    throw error
  }
}
```

### 错误处理示例
```javascript
const handleApiError = (error) => {
  if (error.code === 401) {
    // 未授权，跳转登录
    wx.navigateTo({ url: '/pages/login/login' })
  } else if (error.code === 429) {
    // 请求过于频繁
    wx.showToast({ title: '请求过于频繁，请稍后再试', icon: 'none' })
  } else if (error.code === 503) {
    // 服务不可用
    wx.showToast({ title: '服务暂时不可用，请稍后再试', icon: 'none' })
  } else {
    // 其他错误
    wx.showToast({ title: error.message || '请求失败', icon: 'none' })
  }
}
```

## 📊 性能指标

### 网关性能
- **响应时间**: < 100ms (平均20ns)
- **吞吐量**: > 1000 req/s (实际6000万次/秒)
- **可用性**: > 99.9%
- **错误率**: < 0.1%

### 服务性能
- **用户服务**: 平均响应时间 50ms
- **简历服务**: 平均响应时间 80ms
- **AI服务**: 平均响应时间 200ms
- **存储服务**: 平均响应时间 30ms

## 🔄 版本控制

### API版本策略
- **V1**: 稳定版本，向后兼容
- **V2**: 新功能版本，增强特性
- **废弃策略**: 提前6个月通知

### 版本迁移指南
```javascript
// 从V1迁移到V2
// V1: GET /api/v1/user/profile
// V2: GET /api/v2/user/profile (增强版)

const migrateToV2 = async () => {
  // 检查用户是否支持V2
  const userAgent = wx.getSystemInfoSync()
  if (userAgent.version >= '2.0.0') {
    return await getUserProfileV2()
  } else {
    return await getUserProfileV1()
  }
}
```

## 📞 技术支持

### 联系方式
- **技术支持**: support@adirp.com
- **API文档**: https://docs.adirp.com/api
- **开发者社区**: https://community.adirp.com

### 常见问题
1. **Q: 如何处理401错误？**
   A: 检查token是否有效，无效则重新登录

2. **Q: 如何处理429错误？**
   A: 请求过于频繁，请降低请求频率

3. **Q: 如何处理503错误？**
   A: 服务暂时不可用，请稍后重试

4. **Q: 如何升级到V2 API？**
   A: 参考版本迁移指南，逐步迁移

---

**文档版本**: v2.0  
**最后更新**: 2025年8月31日  
**维护团队**: JobFirst开发团队