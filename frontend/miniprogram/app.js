// app.js
const { API_CONFIG, USE_MOCK } = require('./config/api.js')

App({
  globalData: {
    userInfo: null,
    token: null,
    mode: 'basic', // basic, plus, pro
    apiBaseUrl: API_CONFIG.baseUrl,
    useMock: USE_MOCK,
    features: {
      analytics: false,
      enterprise: false,
      aiChat: false,
      advancedSearch: false
    }
  },

  onLaunch() {
    console.log('小程序启动')
    this.initApp()
  },

  onShow() {
    console.log('小程序显示')
  },

  onHide() {
    console.log('小程序隐藏')
  },

  // 初始化应用
  initApp() {
    // 获取系统信息
    const systemInfo = wx.getSystemInfoSync()
    this.globalData.systemInfo = systemInfo

    // 检查登录状态
    this.checkLoginStatus()

    // 根据模式初始化功能
    this.initFeatures()

    // 检查更新
    this.checkUpdate()
  },

  // 检查登录状态
  checkLoginStatus() {
    const token = wx.getStorageSync('token')
    const userInfo = wx.getStorageSync('userInfo')
    
    if (token && userInfo) {
      this.globalData.token = token
      this.globalData.userInfo = userInfo
      this.validateToken()
    }
  },

  // 验证token有效性
  validateToken() {
    wx.request({
      url: `${this.globalData.apiBaseUrl}/user/validate`,
      method: 'POST',
      header: {
        'Authorization': `Bearer ${this.globalData.token}`
      },
      success: (res) => {
        if (res.data.code !== 200) {
          this.logout()
        }
      },
      fail: () => {
        this.logout()
      }
    })
  },

  // 初始化功能特性
  initFeatures() {
    const mode = this.globalData.mode
    
    switch (mode) {
      case 'basic':
        this.globalData.features = {
          analytics: false,
          enterprise: false,
          aiChat: false,
          advancedSearch: false
        }
        break
      case 'plus':
        this.globalData.features = {
          analytics: true,
          enterprise: false,
          aiChat: true,
          advancedSearch: true
        }
        break
      case 'pro':
        this.globalData.features = {
          analytics: true,
          enterprise: true,
          aiChat: true,
          advancedSearch: true
        }
        break
    }
  },

  // 检查更新
  checkUpdate() {
    if (wx.canIUse('getUpdateManager')) {
      const updateManager = wx.getUpdateManager()
      
      updateManager.onCheckForUpdate((res) => {
        if (res.hasUpdate) {
          updateManager.onUpdateReady(() => {
            wx.showModal({
              title: '更新提示',
              content: '新版本已经准备好，是否重启应用？',
              success: (res) => {
                if (res.confirm) {
                  updateManager.applyUpdate()
                }
              }
            })
          })
        }
      })
    }
  },

  // 登录
  login(userInfo, token) {
    this.globalData.userInfo = userInfo
    this.globalData.token = token
    
    wx.setStorageSync('userInfo', userInfo)
    wx.setStorageSync('token', token)
  },

  // 登出
  logout() {
    this.globalData.userInfo = null
    this.globalData.token = null
    
    wx.removeStorageSync('userInfo')
    wx.removeStorageSync('token')
    
    wx.reLaunch({
      url: '/pages/login/login'
    })
  },

  // 切换模式
  switchMode(mode) {
    this.globalData.mode = mode
    this.initFeatures()
    wx.setStorageSync('mode', mode)
  },

  // 检查功能是否可用
  hasFeature(feature) {
    return this.globalData.features[feature] || false
  },

  // 全局请求方法
  request(options) {
    // 使用 utils/api.js 中的 request 函数
    const { request } = require('./utils/api.js')
    return request(options)
  },

  // 显示提示
  showToast(title, icon = 'none') {
    wx.showToast({
      title,
      icon,
      duration: 2000
    })
  },

  // 显示加载
  showLoading(title = '加载中...') {
    wx.showLoading({
      title,
      mask: true
    })
  },

  // 隐藏加载
  hideLoading() {
    wx.hideLoading()
  }
})
