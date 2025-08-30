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
