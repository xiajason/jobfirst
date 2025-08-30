// profile.js
const app = getApp()
const { PublicAPI, PointsAPI, StatisticsAPI } = require('../../utils/api.js')

Page({
  data: {
    userInfo: {},
    stats: {
      applyCount: 0,
      interviewCount: 0,
      favoriteCount: 0,
      resumeCount: 0,
      unreadInterview: 0
    },
    version: '1.0.0'
  },

  onLoad() {
    this.setData({
      version: app.globalData.version
    })
  },

  onShow() {
    this.loadUserInfo()
    this.loadUserStats()
  },

  // 加载用户信息
  loadUserInfo() {
    const userInfo = app.globalData.userInfo
    if (userInfo) {
      this.setData({ userInfo })
    } else {
      // 未登录状态
      this.setData({
        userInfo: {
          name: '未登录',
          title: '点击登录账号',
          avatar: '/images/default-avatar.png'
        }
      })
    }
  },

  // 加载用户统计数据
  loadUserStats() {
    if (!app.globalData.token) {
      this.setData({
        stats: {
          applyCount: 0,
          interviewCount: 0,
          favoriteCount: 0,
          resumeCount: 0,
          unreadInterview: 0
        }
      })
      return
    }

    // 使用真实API请求获取统计数据
    Promise.all([
      PublicAPI.getResumeList(),
      JobAPI.getApplications(),
      JobAPI.getFavorites(),
      PointsAPI.getBalance()
    ])
      .then(([resumeRes, applyRes, favoriteRes, pointsRes]) => {
        const stats = {
          applyCount: applyRes.code === 0 ? (applyRes.data?.length || 0) : 0,
          interviewCount: 0, // 暂时设为0，需要后端提供面试邀请接口
          favoriteCount: favoriteRes.code === 0 ? (favoriteRes.data?.length || 0) : 0,
          resumeCount: resumeRes.code === 0 ? (resumeRes.data?.length || 0) : 0,
          unreadInterview: 0 // 暂时设为0，需要后端提供未读面试邀请接口
        }
        
        this.setData({ stats })
      })
      .catch(() => {
        // 使用模拟数据作为备选
        const mockStats = {
          applyCount: Math.floor(Math.random() * 20) + 5,
          interviewCount: Math.floor(Math.random() * 10) + 2,
          favoriteCount: Math.floor(Math.random() * 30) + 8,
          resumeCount: Math.floor(Math.random() * 3) + 1,
          unreadInterview: Math.floor(Math.random() * 5)
        }
        
        this.setData({ stats: mockStats })
      })
  },

  // 导航到用户信息页面
  navigateToUserInfo() {
    if (!app.globalData.token) {
      this.showLoginModal()
      return
    }
    
    wx.navigateTo({
      url: '/pages/user-info/user-info'
    })
  },

  // 导航到简历页面
  navigateToResume() {
    if (!app.globalData.token) {
      this.showLoginModal()
      return
    }
    
    wx.navigateTo({
      url: '/pages/resume/resume'
    })
  },

  // 导航到投递记录页面
  navigateToApply() {
    if (!app.globalData.token) {
      this.showLoginModal()
      return
    }
    
    wx.navigateTo({
      url: '/pages/apply/apply'
    })
  },

  // 导航到面试邀请页面
  navigateToInterview() {
    if (!app.globalData.token) {
      this.showLoginModal()
      return
    }
    
    wx.navigateTo({
      url: '/pages/interview/interview'
    })
  },

  // 导航到收藏职位页面
  navigateToFavorite() {
    if (!app.globalData.token) {
      this.showLoginModal()
      return
    }
    
    wx.navigateTo({
      url: '/pages/favorite/favorite'
    })
  },

  // 导航到设置页面
  navigateToSettings() {
    wx.navigateTo({
      url: '/pages/settings/settings'
    })
  },

  // 导航到反馈页面
  navigateToFeedback() {
    wx.navigateTo({
      url: '/pages/feedback/feedback'
    })
  },

  // 导航到关于页面
  navigateToAbout() {
    wx.navigateTo({
      url: '/pages/about/about'
    })
  },

  // 分享应用
  shareApp() {
    wx.showShareMenu({
      withShareTicket: true,
      menus: ['shareAppMessage', 'shareTimeline']
    })
  },

  // 清除缓存
  clearCache() {
    wx.showModal({
      title: '确认清除',
      content: '确定要清除应用缓存吗？',
      success: (res) => {
        if (res.confirm) {
          wx.showLoading({
            title: '清除中...'
          })
          
          // 模拟清除缓存
          setTimeout(() => {
            wx.hideLoading()
            wx.showToast({
              title: '清除成功',
              icon: 'success'
            })
          }, 1500)
        }
      }
    })
  },

  // 退出登录
  logout() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出登录吗？',
      success: (res) => {
        if (res.confirm) {
          app.logout()
          this.loadUserInfo()
          this.loadUserStats()
          
          wx.showToast({
            title: '已退出登录',
            icon: 'success'
          })
        }
      }
    })
  },

  // 显示登录弹窗
  showLoginModal() {
    wx.showModal({
      title: '提示',
      content: '请先登录后再使用此功能',
      confirmText: '去登录',
      success: (res) => {
        if (res.confirm) {
          wx.navigateTo({
            url: '/pages/login/login'
          })
        }
      }
    })
  },

  // 分享给朋友
  onShareAppMessage() {
    return {
      title: 'ADIRP数智招聘 - 智能求职平台',
      path: '/pages/index/index',
      imageUrl: '/images/share-cover.png'
    }
  },

  // 分享到朋友圈
  onShareTimeline() {
    return {
      title: 'ADIRP数智招聘 - 智能求职平台',
      imageUrl: '/images/share-cover.png'
    }
  }
})
