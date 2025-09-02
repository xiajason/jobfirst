# API配置说明

## 概述

本文档说明小程序的API配置和使用方法。

## 当前配置

### 开发环境
- **API地址**: `http://localhost:3000`
- **超时时间**: 10秒
- **重试次数**: 3次
- **Mock数据**: 已启用

### 生产环境
- **API地址**: `https://api.adirp.com`
- **超时时间**: 10秒
- **重试次数**: 3次
- **Mock数据**: 未启用

## 配置文件

### config/api.js
主要的API配置文件，包含：
- 环境配置
- API端点定义
- Mock数据
- 配置导出

### 环境切换
修改 `config/api.js` 中的 `CURRENT_ENV` 变量：
```javascript
const CURRENT_ENV = 'development'  // 开发环境
const CURRENT_ENV = 'production'   // 生产环境
const CURRENT_ENV = 'mock'         // Mock模式
```

## API端点

### 用户相关
- `POST /user/login` - 用户登录
- `POST /user/register` - 用户注册
- `POST /user/sendCode` - 发送验证码
- `GET /user/info` - 获取用户信息
- `POST /user/validate` - 验证token

### 职位相关
- `GET /job/list` - 获取职位列表
- `GET /job/detail` - 获取职位详情
- `GET /job/recommend` - 获取推荐职位
- `POST /job/apply` - 申请职位

### 简历相关
- `GET /resume/list` - 获取简历列表
- `POST /resume/create` - 创建简历
- `PUT /resume/update` - 更新简历

### 统计数据
- `GET /statistics/market` - 获取市场数据
- `GET /statistics/personal` - 获取个人数据

### 其他
- `GET /banner/list` - 获取轮播图
- `GET /industry/hot` - 获取热门行业

## Mock数据

### 轮播图数据
```javascript
banners: [
  {
    id: 1,
    image: '/images/banner1.jpg',
    title: '智能招聘，连接未来',
    link: '/pages/jobs/jobs'
  },
  {
    id: 2,
    image: '/images/banner2.jpg',
    title: 'AI助手，求职更轻松',
    link: '/pages/chat/ai'
  }
]
```

### 职位数据
```javascript
jobs: [
  {
    id: 1,
    title: '前端开发工程师',
    company: '腾讯科技',
    salary: '15K-25K',
    location: '深圳',
    tags: ['React', 'Vue', 'JavaScript']
  }
]
```

### 市场数据
```javascript
marketData: {
  jobCount: '10,000+',
  companyCount: '500+',
  avgSalary: '15K',
  growthRate: '12%'
}
```

## 使用方法

### 1. 在页面中使用API
```javascript
const app = getApp()

// 发起请求
try {
  const res = await app.request({
    url: '/user/login',
    method: 'POST',
    data: {
      phone: '13800138000',
      password: '123456'
    }
  })
  console.log('登录成功:', res)
} catch (error) {
  console.error('登录失败:', error)
}
```

### 2. 使用Mock数据
```javascript
const { MOCK_DATA } = require('../../config/api.js')

// 使用Mock数据
const banners = MOCK_DATA.banners
```

### 3. 错误处理
```javascript
try {
  const res = await app.request({
    url: '/api/endpoint',
    method: 'GET'
  })
  // 处理成功响应
} catch (error) {
  // 处理错误
  console.error('请求失败:', error.message)
  // 使用默认数据
  const defaultData = getDefaultData()
}
```

## 开发建议

### 1. 本地开发
- 使用 `development` 环境
- 启动本地API服务器
- 启用Mock数据作为备用

### 2. 测试环境
- 使用 `production` 环境
- 连接测试服务器
- 关闭Mock数据

### 3. 生产环境
- 使用 `production` 环境
- 连接生产服务器
- 确保API稳定性

## 常见问题

### Q: API请求失败怎么办？
A: 
1. 检查网络连接
2. 确认API服务器状态
3. 查看错误日志
4. 使用Mock数据作为备用

### Q: 如何切换环境？
A: 
1. 修改 `config/api.js` 中的 `CURRENT_ENV`
2. 重新编译小程序
3. 清除缓存

### Q: Mock数据不显示怎么办？
A:
1. 确认 `USE_MOCK` 为 `true`
2. 检查Mock数据格式
3. 查看控制台错误

## 注意事项

1. **网络请求**: 确保网络连接正常
2. **错误处理**: 所有API调用都要有错误处理
3. **Mock数据**: 开发时使用Mock数据避免API依赖
4. **环境配置**: 不同环境使用不同的API地址
5. **超时设置**: 合理设置请求超时时间

## 总结

- 当前使用开发环境配置
- Mock数据已启用，避免API依赖
- 完整的错误处理机制
- 支持多环境切换
