// index.js
const { PublicAPI, JobAPI, CompanyAPI } = require('../../utils/api.js')
const { upgradeManager } = require('../../config/upgrade-config.js')

Page({
  data: {
    banners: [],
    hotJobs: [],
    recommendCompanies: [],
    loading: true,
    upgradeStatus: {}
  },

  onLoad() {
    this.loadData()
    this.checkUpgradeStatus()
  },

  onShow() {
    // 页面显示时刷新数据
    this.loadData()
  },

  // 检查升级状态
  checkUpgradeStatus() {
    try {
      const status = upgradeManager.getUpgradeStatus()
      this.setData({
        upgradeStatus: status
      })
      console.log('当前升级状态:', status)
    } catch (error) {
      console.error('获取升级状态失败:', error)
    }
  },

  // 加载数据
  async loadData() {
    this.setData({ loading: true })
    
    try {
      // 并行加载数据
      const [banners, jobs, companies] = await Promise.all([
        this.loadBanners(),
        this.loadHotJobs(),
        this.loadRecommendCompanies()
      ])

      this.setData({
        banners,
        hotJobs: jobs,
        recommendCompanies: companies,
        loading: false
      })
    } catch (error) {
      console.error('加载数据失败:', error)
      this.setData({ loading: false })
      
      // 显示错误提示
      wx.showToast({
        title: '数据加载失败',
        icon: 'none'
      })
    }
  },

  // 加载轮播图
  async loadBanners() {
    try {
      const response = await PublicAPI.getBanners()
      console.log('轮播图数据:', response)
      
      if (response.code === 200 && response.data) {
        // 检查数据结构
        if (Array.isArray(response.data)) {
          // v1格式
          return response.data.map(item => ({
            id: item.id,
            image: item.image || item.image_url,
            title: item.title,
            link: item.link || item.link_url
          }))
        } else if (response.data.banners) {
          // v2格式
          return response.data.banners.map(item => ({
            id: item.id,
            image: item.image_url,
            title: item.title,
            link: item.link_url
          }))
        }
      }
      
      // 返回默认数据
      return [
        {
          id: 1,
          image: '/images/banner1.jpg',
          title: '春季招聘会',
          link: '/pages/activity/spring'
        },
        {
          id: 2,
          image: '/images/banner2.jpg',
          title: '名企直招',
          link: '/pages/activity/companies'
        },
        {
          id: 3,
          image: '/images/banner3.jpg',
          title: '应届生专场',
          link: '/pages/activity/fresh'
        }
      ]
    } catch (error) {
      console.error('加载轮播图失败:', error)
      return []
    }
  },

  // 加载热门职位
  async loadHotJobs() {
    try {
      const response = await JobAPI.getJobs({ limit: 6 })
      console.log('热门职位数据:', response)
      
      if (response.code === 200 && response.data) {
        // 检查数据结构
        if (Array.isArray(response.data)) {
          // v1格式
          return response.data.map(item => ({
            id: item.id,
            title: item.title,
            company: item.company,
            salary: item.salary,
            location: item.location || '未知'
          }))
        } else if (response.data.jobs) {
          // v2格式
          return response.data.jobs.map(item => ({
            id: item.id,
            title: item.title,
            company: item.company_name,
            salary: `${item.salary_min/1000}k-${item.salary_max/1000}k`,
            location: item.location
          }))
        }
      }
      
      // 返回默认数据
      return [
        {
          id: 1,
          title: '前端开发工程师',
          company: '腾讯',
          salary: '15k-25k',
          location: '深圳'
        },
        {
          id: 2,
          title: '后端开发工程师',
          company: '阿里巴巴',
          salary: '20k-35k',
          location: '杭州'
        },
        {
          id: 3,
          title: '产品经理',
          company: '字节跳动',
          salary: '25k-40k',
          location: '北京'
        }
      ]
    } catch (error) {
      console.error('加载热门职位失败:', error)
      return []
    }
  },

  // 加载推荐企业
  async loadRecommendCompanies() {
    try {
      const response = await CompanyAPI.getRecommendCompanies()
      console.log('推荐企业数据:', response)
      
      if (response.code === 200 && response.data) {
        // 检查数据结构
        if (Array.isArray(response.data)) {
          // v1格式
          return response.data.map(item => ({
            id: item.id,
            name: item.name,
            logo: item.logo,
            description: item.description || '知名企业'
          }))
        } else if (response.data.companies) {
          // v2格式
          return response.data.companies.map(item => ({
            id: item.id,
            name: item.short_name || item.name,
            logo: item.logo_url,
            description: item.description
          }))
        }
      }
      
      // 返回默认数据
      return [
        {
          id: 1,
          name: '腾讯',
          logo: '/images/company/tencent.png',
          description: '互联网科技公司'
        },
        {
          id: 2,
          name: '阿里巴巴',
          logo: '/images/company/alibaba.png',
          description: '电商平台'
        },
        {
          id: 3,
          name: '字节跳动',
          logo: '/images/company/bytedance.png',
          description: '信息科技公司'
        }
      ]
    } catch (error) {
      console.error('加载推荐企业失败:', error)
      return []
    }
  },

  // 轮播图点击
  onBannerTap(e) {
    const { link } = e.currentTarget.dataset
    if (link) {
      wx.navigateTo({
        url: link
      })
    }
  },

  // 职位点击
  onJobTap(e) {
    const { id } = e.currentTarget.dataset
    wx.navigateTo({
      url: `/pages/job/detail?id=${id}`
    })
  },

  // 企业点击
  onCompanyTap(e) {
    const { id } = e.currentTarget.dataset
    wx.navigateTo({
      url: `/pages/company/detail?id=${id}`
    })
  },

  // 查看更多职位
  onMoreJobs() {
    wx.switchTab({
      url: '/pages/jobs/jobs'
    })
  },

  // 查看更多企业
  onMoreCompanies() {
    wx.navigateTo({
      url: '/pages/companies/companies'
    })
  },

  // 搜索职位
  onSearch() {
    wx.switchTab({
      url: '/pages/jobs/jobs'
    })
  },

  // 下拉刷新
  onPullDownRefresh() {
    this.loadData().then(() => {
      wx.stopPullDownRefresh()
    })
  }
})
