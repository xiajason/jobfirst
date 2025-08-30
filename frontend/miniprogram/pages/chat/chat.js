// chat.js
const app = getApp()
const { ChatAPI } = require('../../utils/api.js')

Page({
  data: {
    chatList: [],
    loading: false,
    showFilter: false,
    filter: {
      unread: false,
      online: false,
      timeIndex: 0
    },
    timeOptions: ['全部时间', '今天', '最近3天', '最近一周', '最近一月']
  },

  onLoad() {
    this.loadChatList()
  },

  onShow() {
    this.refreshChatList()
  },

  onPullDownRefresh() {
    this.refreshChatList()
  },

  // 加载聊天列表
  loadChatList() {
    if (this.data.loading) return
    
    this.setData({ loading: true })
    
    // 检查登录状态
    if (!app.globalData.token) {
      this.setData({ 
        chatList: [],
        loading: false 
      })
      wx.stopPullDownRefresh()
      return
    }

    // 使用真实API请求
    ChatAPI.getList()
      .then((res) => {
        if (res.code === 0) {
          this.setData({ 
            chatList: res.data || [],
            loading: false 
          })
        } else {
          // 使用模拟数据作为备选
          const mockChatList = this.generateMockChatList()
          this.setData({ 
            chatList: mockChatList,
            loading: false 
          })
        }
      })
      .catch(() => {
        // 使用模拟数据作为备选
        const mockChatList = this.generateMockChatList()
        this.setData({ 
          chatList: mockChatList,
          loading: false 
        })
      })
      .finally(() => {
        wx.stopPullDownRefresh()
      })
  },

  // 生成模拟聊天数据
  generateMockChatList() {
    const names = ['张HR', '李经理', '王总监', '刘主管', '陈招聘', '赵人事']
    const companies = ['腾讯科技', '阿里巴巴', '字节跳动', '美团', '百度', '京东']
    const positions = ['HR专员', '招聘经理', '人事总监', 'HR主管', '招聘专员', '人事专员']
    const messages = [
      '您好，请问您对我们公司的职位感兴趣吗？',
      '您的简历我们已经收到，请问什么时候方便面试？',
      '面试时间已经安排好了，请准时参加',
      '恭喜您通过面试，请问什么时候可以入职？',
      '您的入职材料已经准备好了，请查收',
      '请问您对薪资待遇有什么要求？'
    ]
    
    const chatList = []
    const count = Math.floor(Math.random() * 8) + 3 // 3-10个聊天
    
    for (let i = 0; i < count; i++) {
      const unreadCount = Math.random() > 0.6 ? Math.floor(Math.random() * 5) + 1 : 0
      
      chatList.push({
        id: Date.now() + i,
        name: names[Math.floor(Math.random() * names.length)],
        avatar: `/images/avatar${Math.floor(Math.random() * 5) + 1}.png`,
        company: companies[Math.floor(Math.random() * companies.length)],
        position: positions[Math.floor(Math.random() * positions.length)],
        lastMessage: messages[Math.floor(Math.random() * messages.length)],
        lastTime: this.getRandomTime(),
        unreadCount: unreadCount,
        isOnline: Math.random() > 0.7
      })
    }
    
    // 按最后消息时间排序
    return chatList.sort((a, b) => {
      return new Date(b.lastTime) - new Date(a.lastTime)
    })
  },

  // 生成随机时间
  getRandomTime() {
    const now = new Date()
    const times = [
      '刚刚',
      '1分钟前',
      '5分钟前',
      '10分钟前',
      '30分钟前',
      '1小时前',
      '2小时前',
      '1天前',
      '2天前',
      '3天前'
    ]
    return times[Math.floor(Math.random() * times.length)]
  },

  // 刷新聊天列表
  refreshChatList() {
    this.loadChatList()
  },

  // 导航到聊天详情
  navigateToChatDetail(e) {
    const chat = e.currentTarget.dataset.chat
    
    // 标记为已读
    this.markAsRead(chat.id)
    
    wx.navigateTo({
      url: `/pages/chat-detail/chat-detail?id=${chat.id}&name=${encodeURIComponent(chat.name)}`
    })
  },

  // 标记为已读
  markAsRead(chatId) {
    const chatList = this.data.chatList.map(item => {
      if (item.id === chatId) {
        return { ...item, unreadCount: 0 }
      }
      return item
    })
    
    this.setData({ chatList })
  },

  // 显示筛选弹窗
  showFilterModal() {
    this.setData({ showFilter: true })
  },

  // 隐藏筛选弹窗
  hideFilterModal() {
    this.setData({ showFilter: false })
  },

  // 阻止事件冒泡
  stopPropagation() {
    // 空函数，用于阻止事件冒泡
  },

  // 切换未读筛选
  toggleUnreadFilter(e) {
    this.setData({
      'filter.unread': e.detail.value
    })
  },

  // 切换在线筛选
  toggleOnlineFilter(e) {
    this.setData({
      'filter.online': e.detail.value
    })
  },

  // 时间筛选变化
  onTimeFilterChange(e) {
    this.setData({
      'filter.timeIndex': e.detail.value
    })
  },

  // 重置筛选
  resetFilter() {
    this.setData({
      filter: {
        unread: false,
        online: false,
        timeIndex: 0
      }
    })
  },

  // 应用筛选
  applyFilter() {
    this.hideFilterModal()
    this.applyFilterToChatList()
  },

  // 应用筛选到聊天列表
  applyFilterToChatList() {
    // 这里可以根据筛选条件重新加载或过滤聊天列表
    // 暂时重新加载所有数据
    this.loadChatList()
  },

  // 标记全部已读
  markAllRead() {
    wx.showModal({
      title: '确认操作',
      content: '确定要将所有消息标记为已读吗？',
      success: (res) => {
        if (res.confirm) {
          const chatList = this.data.chatList.map(item => ({
            ...item,
            unreadCount: 0
          }))
          
          this.setData({ chatList })
          
          wx.showToast({
            title: '已全部标记为已读',
            icon: 'success'
          })
        }
      }
    })
  },

  // 清空聊天记录
  clearHistory() {
    wx.showModal({
      title: '确认清空',
      content: '确定要清空所有聊天记录吗？此操作不可恢复。',
      success: (res) => {
        if (res.confirm) {
          this.setData({ chatList: [] })
          
          wx.showToast({
            title: '已清空聊天记录',
            icon: 'success'
          })
        }
      }
    })
  },

  // 导航到职位页面
  navigateToJobs() {
    wx.switchTab({
      url: '/pages/jobs/jobs'
    })
  },

  // 分享
  onShareAppMessage() {
    return {
      title: 'ADIRP数智招聘 - 智能求职平台',
      path: '/pages/index/index'
    }
  }
})
