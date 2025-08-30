// app.js
const { AuthAPI, PublicAPI } = require('./utils/api.js')  // 使用正确的相对路径  // 使用相对路径 '../utils/api.js'

App({
  globalData: {
    userInfo: null,
    token: null,
    baseUrl: 'http://localhost:8080', // 后端API地址
    version: '1.0.0'
  },

  onLaunch() {
    // 强制修正所有API请求地址
    const originalRequest = wx.request
    wx.request = function(options) {
      // 检查是否有8081端口的请求
      if (typeof options.url === 'string' && options.url.includes(':8081')) {
        console.warn('⚠️ 检测到8081端口请求，正在修正为8080端口:', options.url)
      }
      
      // 统一修正地址
      if (typeof options.url === 'string') {
        options.url = options.url
          .replace('localhost:8081', 'localhost:8080')
          .replace('127.0.0.1:8081', '127.0.0.1:8080')
          .replace(/https?:\/\/[^/]+:8081/, 'http://localhost:8080')
        
        // 确保包含API版本
        if (!options.url.includes('/api/')) {
          options.url = options.url.replace(this.globalData.baseUrl, `${this.globalData.baseUrl}/api/v1`)
        }
      }
      console.log('✅ 请求地址已修正:', options.url)
      return originalRequest(options)
    }
    console.log('小程序启动')
    this.checkLogin()
    this.getSystemInfo()
  },

  onShow() {
    console.log('小程序显示')
  },

  onHide() {
    console.log('小程序隐藏')
  },

  // 检查登录状态
  checkLogin() {
    const token = wx.getStorageSync('token')
    if (token) {
      this.globalData.token = token
      this.getUserInfo()
    }
  },

  // 获取用户信息
  getUserInfo() {
    if (!this.globalData.token) return
    
    PublicAPI.getUserPhone()
      .then((res) => {
        if (res.code === 0) {
          this.globalData.userInfo = res.data
        }
      })
      .catch((err) => {
        console.error('获取用户信息失败:', err)
      })
  },

  // 获取系统信息
  getSystemInfo() {
    // 使用新的API替代废弃的wx.getSystemInfo
    Promise.all([
      wx.getAppBaseInfo(),
      wx.getDeviceInfo(),
      wx.getWindowInfo()
    ]).then(([appBaseInfo, deviceInfo, windowInfo]) => {
      const systemInfo = {
        ...appBaseInfo,
        ...deviceInfo,
        ...windowInfo
      }
      console.log('系统信息:', systemInfo)
      this.globalData.systemInfo = systemInfo
    }).catch((err) => {
      console.error('获取系统信息失败:', err)
    })
  },

  // 登录方法
  login() {
    return new Promise((resolve, reject) => {
      wx.login({
        success: (res) => {
          if (res.code) {
            // 使用新的API接口进行登录
            AuthAPI.wxLogin(res.code)
              .then((loginRes) => {
                if (loginRes.code === 0) {
                  const { accessToken, userInfo } = loginRes.data
                  this.globalData.token = accessToken
                  this.globalData.userInfo = userInfo
                  wx.setStorageSync('token', accessToken)
                  resolve(loginRes)
                } else {
                  reject(new Error(loginRes.msg || '登录失败'))
                }
              })
              .catch(reject)
          } else {
            reject(new Error('登录失败'))
          }
        },
        fail: reject
      })
    })
  },

  // 退出登录
  logout() {
    this.globalData.token = null
    this.globalData.userInfo = null
    wx.removeStorageSync('token')
    wx.reLaunch({
      url: '/pages/index/index'
    })
  }
})
