# ADIRP数智招聘小程序 - API接口适配文档

## 📋 概述

本文档详细说明了微信小程序与后端微服务架构的API接口适配方案，包括接口映射、数据格式转换、错误处理等。

## 🏗️ 后端服务架构

### 微服务架构
```
Gateway Service (8080) - API网关
├── User Service (9001) - 用户服务
├── Resume Service (9002) - 简历服务  
├── Points Service (9004) - 积分服务
├── Statistics Service (9005) - 统计服务
├── Storage Service (9003) - 存储服务
├── Enterprise Service (8002) - 企业服务
├── Open Service (9006) - 开放API服务
└── Blockchain Service (9007) - 区块链服务
```

### 网关路由配置
- `/api/v1/*` - 需要认证的API
- `/open/*` - 公开API，无需认证
- `/resource/*` - 资源服务API
- `/enterprise/*` - 企业端API
- `/resume/*` - 简历服务API
- `/points/*` - 积分服务API
- `/statistics/*` - 统计服务API

## 🔗 API接口映射

### 1. 用户认证相关

#### 微信小程序登录
```
小程序: AuthAPI.wxLogin(code)
后端: POST /api/v1/user/auth/login
数据: { code: "微信登录code" }
响应: { code: 0, data: { accessToken: "token", userInfo: {} }, msg: "登录成功" }
```

#### 检查登录状态
```
小程序: AuthAPI.checkLogin()
后端: GET /api/v1/user/auth/check
响应: { code: 0, data: { valid: true }, msg: "success" }
```

#### 用户登出
```
小程序: AuthAPI.logout()
后端: POST /api/v1/user/auth/logout
响应: { code: 0, data: {}, msg: "登出成功" }
```

### 2. 首页相关

#### 获取轮播图
```
小程序: PublicAPI.getBanners()
后端: GET /api/v1/public/home/banners
响应: { code: 200, data: [{ id, title, image, link }], message: "success" }
```

#### 获取通知
```
小程序: PublicAPI.getNotifications()
后端: GET /api/v1/public/home/notifications
响应: { code: 200, data: [{ id, title, content }], message: "success" }
```

### 3. 职位相关

#### 职位搜索
```
小程序: JobAPI.search(params)
后端: GET /open/job/search
参数: { page, pageSize, keyword, location, salary, experience, filter }
响应: { code: 0, data: [{ id, title, company, location, salary, description }], msg: "success" }
```

#### 职位详情
```
小程序: JobAPI.getDetail(jobId)
后端: GET /open/job/detail/{jobId}
响应: { code: 0, data: { id, title, company, location, salary, description, requirements, benefits }, msg: "success" }
```

#### 推荐职位
```
小程序: JobAPI.getRecommend()
后端: GET /open/job/recommend
响应: { code: 0, data: [{ id, title, company, location, salary }], msg: "success" }
```

#### 热门职位
```
小程序: JobAPI.getHot()
后端: GET /open/job/hot
响应: { code: 0, data: [{ id, title, company, location, salary }], msg: "success" }
```

#### 投递职位
```
小程序: JobAPI.apply(jobId, data)
后端: POST /open/job/apply/{jobId}
数据: { resumeId: 1, coverLetter: "" }
响应: { code: 0, data: { applied: true }, msg: "投递成功" }
```

#### 收藏职位
```
小程序: JobAPI.favorite(jobId)
后端: POST /open/job/favorite/{jobId}
响应: { code: 0, data: { favorited: true }, msg: "收藏成功" }
```

#### 取消收藏
```
小程序: JobAPI.unfavorite(jobId)
后端: DELETE /open/job/favorite/{jobId}
响应: { code: 0, data: { unfavorited: true }, msg: "取消收藏成功" }
```

### 4. 企业相关

#### 企业列表
```
小程序: CompanyAPI.getList(params)
后端: GET /open/company/list
参数: { page, pageSize, keyword, industry, location }
响应: { code: 0, data: [{ id, name, logo, description, size, industry, jobCount }], msg: "success" }
```

#### 企业详情
```
小程序: CompanyAPI.getDetail(companyId)
后端: GET /open/company/detail/{companyId}
响应: { code: 0, data: { id, name, logo, description, size, industry, website, location }, msg: "success" }
```

#### 推荐企业
```
小程序: CompanyAPI.getRecommend()
后端: GET /open/company/recommend
响应: { code: 0, data: [{ id, name, logo, description, size, industry, jobCount }], msg: "success" }
```

### 5. 简历相关

#### 简历列表
```
小程序: PublicAPI.getResumeList()
后端: GET /api/v1/public/mine/resume/list
响应: { code: 0, data: [{ id, title, status, approved, createTime }], msg: "success" }
```

#### 简历详情
```
小程序: PublicAPI.getResumeDetail(id)
后端: GET /api/v1/public/mine/resume/detail/{id}
响应: { code: 0, data: { id, title, content, status, approved, createTime }, msg: "success" }
```

#### 创建简历
```
小程序: PublicAPI.createResume(data)
后端: POST /api/v1/public/mine/resume/create
数据: { title, content, template }
响应: { code: 0, data: { id: 1, status: "created" }, msg: "创建成功" }
```

#### 更新简历
```
小程序: PublicAPI.updateResume(id, data)
后端: PUT /api/v1/public/mine/resume/update/{id}
数据: { title, content }
响应: { code: 0, data: { updated: true }, msg: "更新成功" }
```

### 6. 聊天相关

#### 聊天列表
```
小程序: ChatAPI.getList()
后端: GET /chat/list
响应: { code: 0, data: [{ id, name, avatar, company, position, lastMessage, lastTime, unreadCount, isOnline }], msg: "success" }
```

#### 聊天详情
```
小程序: ChatAPI.getDetail(chatId)
后端: GET /chat/detail/{chatId}
响应: { code: 0, data: { id, name, avatar, company, position, messages: [] }, msg: "success" }
```

#### 发送消息
```
小程序: ChatAPI.sendMessage(chatId, data)
后端: POST /chat/{chatId}/message
数据: { content, type: "text" }
响应: { code: 0, data: { messageId: 1, sent: true }, msg: "发送成功" }
```

#### 标记已读
```
小程序: ChatAPI.markRead(chatId)
后端: PUT /chat/{chatId}/read
响应: { code: 0, data: { marked: true }, msg: "标记成功" }
```

### 7. 积分相关

#### 积分余额
```
小程序: PointsAPI.getBalance()
后端: GET /points/balance
响应: { code: 0, data: { balance: 1000, level: "gold" }, msg: "success" }
```

#### 积分记录
```
小程序: PointsAPI.getHistory(params)
后端: GET /points/history
参数: { page, pageSize, type }
响应: { code: 0, data: [{ id, type, amount, description, time }], msg: "success" }
```

#### 积分规则
```
小程序: PointsAPI.getRules()
后端: GET /points/rules
响应: { code: 0, data: [{ action, description, points }], msg: "success" }
```

### 8. 统计相关

#### 统计概览
```
小程序: StatisticsAPI.getOverview()
后端: GET /statistics/overview
响应: { code: 0, data: { total_users, total_resumes, total_jobs, total_enterprises }, msg: "success" }
```

#### 用户统计
```
小程序: StatisticsAPI.getUserStats()
后端: GET /statistics/users
响应: { code: 0, data: { total_users, active_users, new_users_today, new_users_week }, msg: "success" }
```

## 🔧 数据格式适配

### 响应码映射
```javascript
// 后端响应码
const BACKEND_CODES = {
  SUCCESS: 0,        // 成功
  ERROR: 500,        // 错误
  UNAUTHORIZED: 401,  // 未授权
  FORBIDDEN: 403,     // 禁止访问
  NOT_FOUND: 404     // 未找到
}

// 小程序响应码
const MINIPROGRAM_CODES = {
  SUCCESS: 200,      // 成功
  ERROR: 500,        // 错误
  UNAUTHORIZED: 401,  // 未授权
  FORBIDDEN: 403,     // 禁止访问
  NOT_FOUND: 404     // 未找到
}
```

### 数据格式转换
```javascript
// 后端响应格式
{
  code: 0,
  data: { ... },
  msg: "success"
}

// 小程序期望格式
{
  code: 200,
  data: { ... },
  message: "success"
}
```

### 错误处理
```javascript
// 统一错误处理
const handleResponse = (response) => {
  if (response.code === 0) {
    return {
      success: true,
      data: response.data,
      message: response.msg
    }
  } else {
    return {
      success: false,
      error: response.msg || '请求失败',
      code: response.code
    }
  }
}
```

## 🔐 认证机制

### Token管理
```javascript
// 存储Token
wx.setStorageSync('token', accessToken)

// 获取Token
const token = wx.getStorageSync('token')

// 清除Token
wx.removeStorageSync('token')
```

### 请求拦截
```javascript
// 自动添加认证头
const request = (options) => {
  const token = wx.getStorageSync('token')
  if (token) {
    options.header = {
      ...options.header,
      'Authorization': `Bearer ${token}`
    }
  }
  return wx.request(options)
}
```

### 认证失败处理
```javascript
// 401错误处理
if (response.statusCode === 401) {
  // 清除本地Token
  wx.removeStorageSync('token')
  
  // 跳转到登录页
  wx.reLaunch({
    url: '/pages/login/login'
  })
}
```

## 🚀 部署配置

### 开发环境
```javascript
const API_CONFIG = {
  BASE_URL: 'http://localhost:8080',
  SUCCESS_CODE: 200,
  ERROR_CODE: 500
}
```

### 生产环境
```javascript
const API_CONFIG = {
  BASE_URL: 'https://api.jobfirst.com',
  SUCCESS_CODE: 200,
  ERROR_CODE: 500
}
```

### 测试环境
```javascript
const API_CONFIG = {
  BASE_URL: 'https://test-api.jobfirst.com',
  SUCCESS_CODE: 200,
  ERROR_CODE: 500
}
```

## 📱 小程序配置

### 网络请求配置
```json
{
  "networkTimeout": {
    "request": 10000,
    "connectSocket": 10000,
    "uploadFile": 10000,
    "downloadFile": 10000
  }
}
```

### 域名配置
```json
{
  "requestDomain": ["https://api.jobfirst.com"],
  "uploadDomain": ["https://api.jobfirst.com"],
  "downloadDomain": ["https://api.jobfirst.com"]
}
```

## 🔄 联调联试流程

### 1. 环境准备
- 启动后端微服务
- 配置网关服务
- 启动小程序开发工具

### 2. 接口测试
- 测试公开接口（无需认证）
- 测试认证接口（需要Token）
- 测试文件上传接口

### 3. 数据验证
- 验证请求参数格式
- 验证响应数据格式
- 验证错误处理机制

### 4. 性能测试
- 测试接口响应时间
- 测试并发请求处理
- 测试大数据量处理

### 5. 兼容性测试
- 测试不同微信版本
- 测试不同设备型号
- 测试不同网络环境

## 📝 注意事项

### 1. 接口兼容性
- 保持向后兼容
- 版本号管理
- 废弃接口处理

### 2. 数据安全
- HTTPS传输
- 敏感数据加密
- 接口权限控制

### 3. 性能优化
- 请求缓存
- 图片压缩
- 分页加载

### 4. 错误处理
- 网络错误处理
- 业务错误处理
- 用户友好提示

## 🔧 开发工具

### 接口调试
- Postman
- Charles
- 微信开发者工具

### 监控工具
- 日志监控
- 性能监控
- 错误监控

### 测试工具
- 单元测试
- 集成测试
- 端到端测试

---

© 2024 ADIRP数智招聘. All rights reserved.
