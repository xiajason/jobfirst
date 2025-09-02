// index.js
const app = getApp()
const { MOCK_DATA } = require('../../config/api.js')

Page({
  data: {
    mode: 'basic',
    modeText: '基础版',
    hasAnalytics: false,
    hasAIChat: false,
    hasEnterprise: false,
    banners: [],
    quickActions: [],
    recommendJobs: [],
    marketData: {},
    enterpriseServices: [],
    industries: []
  },

  onLoad() {
    this.initPage()
  },

  onShow() {
    this.loadData()
  },

  onPullDownRefresh() {
    this.loadData()
    wx.stopPullDownRefresh()
  },

  // 初始化页面
  initPage() {
    const mode = app.globalData.mode
    this.setData({
      mode,
      modeText: this.getModeText(mode),
      hasAnalytics: app.hasFeature('analytics'),
      hasAIChat: app.hasFeature('aiChat'),
      hasEnterprise: app.hasFeature('enterprise')
    })
  },

  // 获取模式文本
  getModeText(mode) {
    const modeMap = {
      'basic': '基础版',
      'plus': '增强版',
      'pro': '专业版'
    }
    return modeMap[mode] || '基础版'
  },

  // 加载数据
  async loadData() {
    try {
      app.showLoading()
      
      // 并行加载数据
      const [
        banners,
        quickActions,
        recommendJobs,
        marketData,
        enterpriseServices,
        industries
      ] = await Promise.all([
        this.loadBanners(),
        this.loadQuickActions(),
        this.loadRecommendJobs(),
        this.loadMarketData(),
        this.loadEnterpriseServices(),
        this.loadIndustries()
      ])

      this.setData({
        banners,
        quickActions,
        recommendJobs,
        marketData,
        enterpriseServices,
        industries
      })
    } catch (error) {
      console.error('加载数据失败:', error)
      app.showToast('加载失败，请重试')
    } finally {
      app.hideLoading()
    }
  },

  // 加载轮播图
  async loadBanners() {
    try {
      const res = await app.request({
        url: '/banner/list',
        method: 'GET'
      })
      return res.data || []
    } catch (error) {
      console.error('加载轮播图失败:', error)
      return this.getDefaultBanners()
    }
  },

  // 加载快捷功能
  async loadQuickActions() {
    const actions = [
      { id: 1, icon: '📝', text: '投递简历', action: 'resume' },
      { id: 2, icon: '🔍', text: '职位搜索', action: 'search' },
      { id: 3, icon: '💼', text: '我的申请', action: 'applications' },
      { id: 4, icon: '⭐', text: '收藏职位', action: 'favorites' }
    ]

    // 根据模式添加额外功能
    if (this.data.hasAIChat) {
      actions.push({ id: 5, icon: '🤖', text: 'AI助手', action: 'aiChat' })
    }

    if (this.data.hasEnterprise) {
      actions.push({ id: 6, icon: '🏢', text: '企业服务', action: 'enterprise' })
    }

    return actions
  },

  // 加载推荐职位
  async loadRecommendJobs() {
    try {
      const res = await app.request({
        url: '/job/recommend',
        method: 'GET',
        data: { limit: 5 }
      })
      return res.data || []
    } catch (error) {
      console.error('加载推荐职位失败:', error)
      return this.getDefaultJobs()
    }
  },

  // 加载市场数据
  async loadMarketData() {
    if (!this.data.hasAnalytics) {
      return {}
    }

    try {
      const res = await app.request({
        url: '/statistics/market',
        method: 'GET'
      })
      return res.data || {}
    } catch (error) {
      console.error('加载市场数据失败:', error)
      return MOCK_DATA.marketData || {
        jobCount: '10,000+',
        companyCount: '500+',
        avgSalary: '15K'
      }
    }
  },

  // 加载企业服务
  async loadEnterpriseServices() {
    if (!this.data.hasEnterprise) {
      return []
    }

    return [
      {
        id: 1,
        icon: '📊',
        title: '招聘数据分析',
        description: '深度分析招聘市场趋势'
      },
      {
        id: 2,
        icon: '🎯',
        title: '精准人才匹配',
        description: 'AI智能推荐合适人才'
      },
      {
        id: 3,
        icon: '📈',
        title: '招聘效果评估',
        description: '全面评估招聘ROI'
      }
    ]
  },

  // 加载热门行业
  async loadIndustries() {
    try {
      const res = await app.request({
        url: '/industry/hot',
        method: 'GET'
      })
      return res.data || []
    } catch (error) {
      console.error('加载热门行业失败:', error)
      return this.getDefaultIndustries()
    }
  },

  // 获取默认轮播图
  getDefaultBanners() {
    return MOCK_DATA.banners || [
      {
        id: 1,
        image: '/images/banner1.svg',
        title: '春季招聘会',
        link: '/pages/event/spring'
      },
      {
        id: 2,
        image: '/images/banner2.svg',
        title: 'AI技术专场',
        link: '/pages/event/ai'
      }
    ]
  },

  // 获取默认职位
  getDefaultJobs() {
    return MOCK_DATA.jobs || [
      {
        id: 1,
        title: '前端开发工程师',
        salary: '15K-25K',
        company: '腾讯科技',
        location: '深圳',
        time: '2小时前',
        tags: ['React', 'Vue', '3年+']
      },
      {
        id: 2,
        title: '产品经理',
        salary: '20K-35K',
        company: '阿里巴巴',
        location: '杭州',
        time: '4小时前',
        tags: ['产品设计', '用户增长', '5年+']
      }
    ]
  },

  // 获取默认行业
  getDefaultIndustries() {
    return [
      {
        id: 1,
        name: '互联网',
        icon: '/images/industry/internet.svg',
        jobCount: 5000
      },
      {
        id: 2,
        name: '金融',
        icon: '/images/industry/finance.svg',
        jobCount: 3000
      },
      {
        id: 3,
        name: '教育',
        icon: '/images/industry/education.svg',
        jobCount: 2000
      }
    ]
  },

  // 事件处理
  goToSearch() {
    wx.navigateTo({
      url: '/pages/search/search'
    })
  },

  onBannerTap(e) {
    const item = e.currentTarget.dataset.item
    if (item.link) {
      wx.navigateTo({
        url: item.link
      })
    }
  },

  onActionTap(e) {
    const action = e.currentTarget.dataset.action
    switch (action.action) {
      case 'resume':
        wx.navigateTo({ url: '/pages/resume/resume' })
        break
      case 'search':
        wx.navigateTo({ url: '/pages/search/search' })
        break
      case 'applications':
        wx.navigateTo({ url: '/pages/applications/applications' })
        break
      case 'favorites':
        wx.navigateTo({ url: '/pages/favorites/favorites' })
        break
      case 'aiChat':
        wx.navigateTo({ url: '/pages/chat/ai' })
        break
      case 'enterprise':
        wx.navigateTo({ url: '/pages/enterprise/enterprise' })
        break
    }
  },

  goToJobs() {
    wx.switchTab({
      url: '/pages/jobs/jobs'
    })
  },

  goToJobDetail(e) {
    const id = e.currentTarget.dataset.id
    wx.navigateTo({
      url: `/pages/job/detail?id=${id}`
    })
  },

  goToAIChat() {
    wx.navigateTo({
      url: '/pages/chat/ai'
    })
  },

  goToEnterprise(e) {
    const service = e.currentTarget.dataset.service
    wx.navigateTo({
      url: `/pages/enterprise/service?id=${service.id}`
    })
  },

  goToIndustry(e) {
    const industry = e.currentTarget.dataset.industry
    wx.navigateTo({
      url: `/pages/industry/detail?id=${industry.id}`
    })
  },

  goToUpgrade() {
    wx.navigateTo({
      url: '/pages/upgrade/upgrade'
    })
  }
})
