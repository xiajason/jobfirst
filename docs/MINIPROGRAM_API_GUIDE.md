# JobFirst 小程序API使用指南

## 📋 概述

本指南介绍如何在JobFirst小程序中使用后端API。小程序已经配置了完整的HTTP工具类，支持个人端服务和资源服务的所有API调用。

## 🏗️ 配置说明

### API配置 (`config/index.ts`)

```typescript
export const config = {
  // 个人端服务API地址
  personal_base_url: 'http://localhost:6001/personal',
  
  // 资源服务API地址
  resource_base_url: 'http://localhost:9002/resource',
  
  // 网关API地址（备用）
  api_base_url: 'http://localhost:8080/api/v1',
  
  // 通用配置
  timeout: 10000,
  retry_times: 3
}
```

### HTTP工具类 (`utils/http.ts`)

HTTP工具类已经更新，支持多服务API调用，并提供了便捷的方法封装。

## 🚀 使用示例

### 1. 基础使用

```typescript
import HTTP from '../utils/http'

const http = new HTTP()

// 基础请求
http.request('/api/path', { param: 'value' }, { data: 'value' }, 'POST', 'personal')
```

### 2. 用户认证相关

```typescript
// 用户登录
const login = async () => {
  try {
    const result = await http.personal.login({
      username: 'test',
      password: '123456'
    })
    console.log('登录成功:', result)
    // 保存token
    wx.setStorageSync('accessToken', result.accessToken)
  } catch (error) {
    console.error('登录失败:', error)
  }
}

// 检查登录状态
const checkLogin = async () => {
  try {
    const result = await http.personal.checkLogin()
    console.log('登录状态:', result)
  } catch (error) {
    console.error('检查登录失败:', error)
  }
}

// 获取用户手机号
const getUserPhone = async () => {
  try {
    const result = await http.personal.getUserPhone()
    console.log('用户手机号:', result.phone)
  } catch (error) {
    console.error('获取手机号失败:', error)
  }
}

// 用户登出
const logout = async () => {
  try {
    await http.personal.logout()
    wx.removeStorageSync('accessToken')
    console.log('登出成功')
  } catch (error) {
    console.error('登出失败:', error)
  }
}
```

### 3. 简历管理相关

```typescript
// 获取简历列表
const getResumeList = async () => {
  try {
    const result = await http.personal.getResumeList()
    console.log('简历列表:', result)
    return result
  } catch (error) {
    console.error('获取简历列表失败:', error)
  }
}

// 创建简历
const createResume = async (resumeData: any) => {
  try {
    const result = await http.personal.createResume(resumeData)
    console.log('简历创建成功:', result)
    return result
  } catch (error) {
    console.error('创建简历失败:', error)
  }
}

// 获取简历详情
const getResumeDetail = async (resumeId: string) => {
  try {
    const result = await http.personal.getResumeDetail(resumeId)
    console.log('简历详情:', result)
    return result
  } catch (error) {
    console.error('获取简历详情失败:', error)
  }
}

// 发布简历
const publishResume = async (resumeId: string) => {
  try {
    const result = await http.personal.publishResume(resumeId)
    console.log('简历发布成功:', result)
    return result
  } catch (error) {
    console.error('发布简历失败:', error)
  }
}

// 获取简历模板
const getResumeTemplates = async () => {
  try {
    const result = await http.personal.getResumeTemplates()
    console.log('简历模板:', result)
    return result
  } catch (error) {
    console.error('获取简历模板失败:', error)
  }
}
```

### 4. 首页相关

```typescript
// 获取首页横幅
const getBanners = async () => {
  try {
    const result = await http.personal.getBanners()
    console.log('首页横幅:', result)
    return result
  } catch (error) {
    console.error('获取横幅失败:', error)
  }
}

// 获取通知
const getNotifications = async () => {
  try {
    const result = await http.personal.getNotifications()
    console.log('通知列表:', result)
    return result
  } catch (error) {
    console.error('获取通知失败:', error)
  }
}
```

### 5. 个人中心相关

```typescript
// 获取用户信息
const getUserInfo = async () => {
  try {
    const result = await http.personal.getUserInfo()
    console.log('用户信息:', result)
    return result
  } catch (error) {
    console.error('获取用户信息失败:', error)
  }
}

// 获取积分信息
const getPoints = async () => {
  try {
    const result = await http.personal.getPoints()
    console.log('积分信息:', result)
    return result
  } catch (error) {
    console.error('获取积分失败:', error)
  }
}

// 获取积分账单
const getPointsBill = async () => {
  try {
    const result = await http.personal.getPointsBill()
    console.log('积分账单:', result)
    return result
  } catch (error) {
    console.error('获取积分账单失败:', error)
  }
}
```

### 6. 资源管理相关

```typescript
// 获取资源URL列表
const getResourceUrls = async () => {
  try {
    const result = await http.resource.getUrls()
    console.log('资源URL列表:', result)
    return result
  } catch (error) {
    console.error('获取资源URL失败:', error)
  }
}

// 上传文件
const uploadFile = async (filePath: string, fileName: string) => {
  try {
    const result = await http.resource.upload({
      filePath,
      name: fileName
    })
    console.log('文件上传成功:', result)
    return result
  } catch (error) {
    console.error('文件上传失败:', error)
  }
}

// OCR识别
const ocrGeneral = async (imageData: any) => {
  try {
    const result = await http.resource.ocrGeneral(imageData)
    console.log('OCR识别结果:', result)
    return result
  } catch (error) {
    console.error('OCR识别失败:', error)
  }
}

// 获取字典数据
const getDictData = async (type: string) => {
  try {
    const result = await http.resource.getDictData(type)
    console.log('字典数据:', result)
    return result
  } catch (error) {
    console.error('获取字典数据失败:', error)
  }
}
```

## 📱 页面使用示例

### 首页页面

```typescript
// pages/index/index.ts
import HTTP from '../../utils/http'

Page({
  data: {
    banners: [],
    notifications: []
  },

  onLoad() {
    this.loadHomeData()
  },

  async loadHomeData() {
    const http = new HTTP()
    
    try {
      // 并行加载数据
      const [banners, notifications] = await Promise.all([
        http.personal.getBanners(),
        http.personal.getNotifications()
      ])
      
      this.setData({
        banners,
        notifications
      })
    } catch (error) {
      console.error('加载首页数据失败:', error)
    }
  }
})
```

### 简历列表页面

```typescript
// pages/resume/list.ts
import HTTP from '../../utils/http'

Page({
  data: {
    resumeList: []
  },

  onLoad() {
    this.loadResumeList()
  },

  async loadResumeList() {
    const http = new HTTP()
    
    try {
      const result = await http.personal.getResumeList()
      this.setData({
        resumeList: result
      })
    } catch (error) {
      console.error('加载简历列表失败:', error)
    }
  },

  async createResume() {
    const http = new HTTP()
    
    try {
      const result = await http.personal.createResume({
        title: '新简历',
        template: 'classic'
      })
      
      wx.showToast({
        title: '简历创建成功',
        icon: 'success'
      })
      
      // 刷新列表
      this.loadResumeList()
    } catch (error) {
      console.error('创建简历失败:', error)
    }
  }
})
```

### 用户登录页面

```typescript
// pages/login/login.ts
import HTTP from '../../utils/http'

Page({
  data: {
    username: '',
    password: ''
  },

  onInput(e: any) {
    const { field } = e.currentTarget.dataset
    this.setData({
      [field]: e.detail.value
    })
  },

  async onLogin() {
    const { username, password } = this.data
    
    if (!username || !password) {
      wx.showToast({
        title: '请输入用户名和密码',
        icon: 'none'
      })
      return
    }

    const http = new HTTP()
    
    try {
      const result = await http.personal.login({
        username,
        password
      })
      
      // 保存token
      wx.setStorageSync('accessToken', result.accessToken)
      
      wx.showToast({
        title: '登录成功',
        icon: 'success'
      })
      
      // 跳转到首页
      wx.switchTab({
        url: '/pages/index/index'
      })
    } catch (error) {
      console.error('登录失败:', error)
    }
  }
})
```

## 🔧 错误处理

### 统一错误处理

```typescript
// 自定义错误处理
const handleApiError = (error: any, customMessage?: string) => {
  console.error('API Error:', error)
  
  let message = customMessage || '请求失败'
  
  if (error.errMsg && error.errMsg.includes('timeout')) {
    message = '网络超时，请重试'
  } else if (error.code === 100001 || error.code === 100002) {
    message = '登录已过期，请重新登录'
    // 跳转到登录页
    wx.redirectTo({
      url: '/pages/login/login'
    })
  } else if (error.msg) {
    message = error.msg
  }
  
  wx.showToast({
    title: message,
    icon: 'none',
    duration: 2000
  })
}

// 使用示例
const safeApiCall = async (apiCall: () => Promise<any>, customMessage?: string) => {
  try {
    return await apiCall()
  } catch (error) {
    handleApiError(error, customMessage)
    throw error
  }
}
```

## 📊 API状态监控

### 健康检查

```typescript
// 检查API服务状态
const checkApiHealth = async () => {
  const http = new HTTP()
  
  try {
    // 检查个人端服务
    await http.request('/version', {}, {}, 'GET', 'personal')
    console.log('个人端服务正常')
    
    // 检查资源服务
    await http.request('/version', {}, {}, 'GET', 'resource')
    console.log('资源服务正常')
    
    return true
  } catch (error) {
    console.error('API服务异常:', error)
    return false
  }
}
```

## 🎯 最佳实践

1. **统一错误处理**: 使用统一的错误处理函数
2. **Promise.all**: 并行请求多个API提高性能
3. **缓存策略**: 对不常变化的数据进行缓存
4. **加载状态**: 显示加载状态提升用户体验
5. **重试机制**: 对网络请求失败进行重试
6. **Token管理**: 正确管理用户登录token

## 📝 注意事项

1. **网络环境**: 确保小程序在正确的网络环境下运行
2. **域名配置**: 在小程序后台配置API域名白名单
3. **HTTPS**: 生产环境必须使用HTTPS协议
4. **超时设置**: 合理设置请求超时时间
5. **错误提示**: 提供友好的错误提示信息

---

**JobFirst 小程序API使用指南** - 让小程序开发更简单、更高效！
