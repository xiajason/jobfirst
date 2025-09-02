// pages/profile/profile.js
const app = getApp()

Page({
  data: {
    userInfo: {},
    stats: {},
    isLoggedIn: false,
    version: '1.0.0',
    modeText: '基础版'
  },

  onLoad() {
    this.initPage()
  },

  onShow() {
    this.loadUserInfo()
    this.loadStats()
  },

  // 初始化页面
  initPage() {
    const mode = app.globalData.mode
    let modeText = '基础版'
    
    switch (mode) {
      case 'plus':
        modeText = '增强版'
        break
      case 'pro':
        modeText = '专业版'
        break
    }
    
    this.setData({
      modeText,
      isLoggedIn: !!app.globalData.token
    })
  },

  // 加载用户信息
  loadUserInfo() {
    if (app.globalData.userInfo) {
      this.setData({
        userInfo: app.globalData.userInfo
      })
    } else {
      // 如果没有用户信息但有token，尝试获取用户信息
      if (app.globalData.token) {
        this.fetchUserInfo()
      }
    }
  },

  // 获取用户信息
  async fetchUserInfo() {
    try {
      const res = await app.request({
        url: '/api/user/info',
        method: 'GET'
      })

      if (res.success) {
        app.globalData.userInfo = res.data
        this.setData({
          userInfo: res.data
        })
      }
    } catch (error) {
      console.error('获取用户信息失败:', error)
    }
  },

  // 加载统计数据
  async loadStats() {
    if (!app.globalData.token) return

    try {
      const res = await app.request({
        url: '/api/user/stats',
        method: 'GET'
      })

      if (res.success) {
        this.setData({
          stats: res.data
        })
      }
    } catch (error) {
      console.error('获取统计数据失败:', error)
    }
  },

  // 跳转到投递记录
  goToApplications() {
    if (!this.checkLogin()) return
    
    wx.navigateTo({
      url: '/pages/applications/applications'
    })
  },

  // 跳转到收藏
  goToFavorites() {
    if (!this.checkLogin()) return
    
    wx.navigateTo({
      url: '/pages/favorites/favorites'
    })
  },

  // 跳转到简历
  goToResume() {
    if (!this.checkLogin()) return
    
    wx.navigateTo({
      url: '/pages/resume/resume'
    })
  },

  // 跳转到数据分析
  goToAnalytics() {
    if (!this.checkLogin()) return
    
    wx.navigateTo({
      url: '/pages/analytics/analytics'
    })
  },

  // 跳转到企业服务
  goToEnterprise() {
    if (!this.checkLogin()) return
    
    wx.navigateTo({
      url: '/pages/enterprise/enterprise'
    })
  },

  // 跳转到设置
  goToSettings() {
    wx.navigateTo({
      url: '/pages/settings/settings'
    })
  },

  // 显示反馈
  showFeedback() {
    wx.showModal({
      title: '意见反馈',
      content: '如有问题或建议，请联系客服：\n400-123-4567',
      showCancel: false
    })
  },

  // 显示关于
  showAbout() {
    wx.showModal({
      title: '关于我们',
      content: `ADIRP数智招聘 v${this.data.version}\n\n智能招聘，连接未来\n\n客服电话：400-123-4567\n邮箱：support@adirp.com`,
      showCancel: false
    })
  },

  // 检查登录状态
  checkLogin() {
    if (!app.globalData.token) {
      wx.showModal({
        title: '提示',
        content: '请先登录',
        confirmText: '去登录',
        success: (res) => {
          if (res.confirm) {
            wx.navigateTo({
              url: '/pages/login/login'
            })
          }
        }
      })
      return false
    }
    return true
  },

  // 退出登录
  logout() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出登录吗？',
      success: (res) => {
        if (res.confirm) {
          app.logout()
          this.setData({
            userInfo: {},
            stats: {},
            isLoggedIn: false
          })
          app.showToast('已退出登录')
        }
      }
    })
  }
})
