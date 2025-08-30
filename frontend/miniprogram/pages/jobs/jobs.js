// jobs.js
const app = getApp()
const { JobAPI } = require('../../utils/api.js')

Page({
  data: {
    // 筛选条件
    currentFilter: 'all',
    selectedLocation: '',
    selectedSalary: '',
    selectedExperience: '',
    searchKeyword: '',
    
    // 选择器选项
    salaryOptions: ['不限', '3k以下', '3k-5k', '5k-10k', '10k-15k', '15k-25k', '25k-35k', '35k-50k', '50k以上'],
    experienceOptions: ['不限', '应届生', '1年以下', '1-3年', '3-5年', '5-10年', '10年以上'],
    
    // 选择器状态
    showLocationPicker: false,
    showSalaryPicker: false,
    showExperiencePicker: false,
    
    // 列表数据
    jobs: [],
    loading: false,
    hasMore: true,
    page: 1,
    pageSize: 10
  },

  onLoad(options) {
    // 处理从首页传递的参数
    if (options.type) {
      this.setData({ currentFilter: options.type })
    }
    this.loadJobs()
  },

  onShow() {
    // 页面显示时刷新数据
    this.refreshJobs()
  },

  onPullDownRefresh() {
    this.refreshJobs()
  },

  onReachBottom() {
    if (this.data.hasMore && !this.data.loading) {
      this.loadMore()
    }
  },

  // 设置筛选条件
  setFilter(e) {
    const type = e.currentTarget.dataset.type
    this.setData({ 
      currentFilter: type,
      page: 1,
      hasMore: true
    })
    this.loadJobs()
  },

  // 显示地点选择器
  showLocationPicker() {
    this.setData({ showLocationPicker: true })
  },

  // 显示薪资选择器
  showSalaryPicker() {
    this.setData({ showSalaryPicker: true })
  },

  // 显示经验选择器
  showExperiencePicker() {
    this.setData({ showExperiencePicker: true })
  },

  // 地点选择变化
  onLocationChange(e) {
    const location = e.detail.value.join(' ')
    this.setData({ 
      selectedLocation: location,
      page: 1,
      hasMore: true
    })
    this.loadJobs()
  },

  // 薪资选择变化
  onSalaryChange(e) {
    const salary = this.data.salaryOptions[e.detail.value]
    this.setData({ 
      selectedSalary: salary,
      page: 1,
      hasMore: true
    })
    this.loadJobs()
  },

  // 经验选择变化
  onExperienceChange(e) {
    const experience = this.data.experienceOptions[e.detail.value]
    this.setData({ 
      selectedExperience: experience,
      page: 1,
      hasMore: true
    })
    this.loadJobs()
  },

  // 搜索输入
  onSearchInput(e) {
    this.setData({
      searchKeyword: e.detail.value
    })
  },

  // 搜索确认
  onSearch() {
    this.setData({
      page: 1,
      hasMore: true
    })
    this.loadJobs()
  },

  // 加载职位列表
  loadJobs() {
    if (this.data.loading) return
    
    this.setData({ loading: true })
    
    // 构建请求参数
    const params = {
      page: this.data.page,
      pageSize: this.data.pageSize,
      filter: this.data.currentFilter,
      keyword: this.data.searchKeyword,
      location: this.data.selectedLocation,
      salary: this.data.selectedSalary,
      experience: this.data.selectedExperience
    }

    // 使用真实API请求
    JobAPI.search(params)
      .then((res) => {
        if (res.code === 0) {
          const jobs = res.data || []
          
          if (this.data.page === 1) {
            this.setData({ jobs })
          } else {
            this.setData({ 
              jobs: [...this.data.jobs, ...jobs]
            })
          }
          
          this.setData({ 
            loading: false,
            hasMore: jobs.length === this.data.pageSize
          })
        } else {
          // 使用模拟数据作为备选
          const mockJobs = this.generateMockJobs(params)
          
          if (this.data.page === 1) {
            this.setData({ jobs: mockJobs })
          } else {
            this.setData({ 
              jobs: [...this.data.jobs, ...mockJobs]
            })
          }
          
          this.setData({ 
            loading: false,
            hasMore: mockJobs.length === this.data.pageSize
          })
        }
      })
      .catch(() => {
        // 使用模拟数据作为备选
        const mockJobs = this.generateMockJobs(params)
        
        if (this.data.page === 1) {
          this.setData({ jobs: mockJobs })
        } else {
          this.setData({ 
            jobs: [...this.data.jobs, ...mockJobs]
          })
        }
        
        this.setData({ 
          loading: false,
          hasMore: mockJobs.length === this.data.pageSize
        })
      })
      .finally(() => {
        wx.stopPullDownRefresh()
      })
  },

  // 生成模拟数据
  generateMockJobs(params) {
    const jobTitles = [
      '前端开发工程师', '后端开发工程师', '产品经理', 'UI设计师', 
      '算法工程师', '数据分析师', '运营专员', '市场专员',
      '销售代表', '客服专员', '人事专员', '财务专员'
    ]
    
    const companies = [
      '腾讯科技', '阿里巴巴', '字节跳动', '美团', '百度', '京东',
      '网易', '小米', '华为', 'OPPO', 'vivo', '滴滴出行'
    ]
    
    const locations = ['北京', '上海', '深圳', '广州', '杭州', '成都', '武汉', '西安']
    const salaries = ['8k-12k', '12k-18k', '15k-25k', '20k-35k', '25k-40k', '30k-50k']
    const experiences = ['应届生', '1-3年', '3-5年', '5-8年', '8年以上']
    const educations = ['大专', '本科', '硕士', '博士']
    const tags = ['React', 'Vue', 'TypeScript', 'Python', 'Java', 'Go', 'MySQL', 'Redis', 'Docker', 'Kubernetes']
    
    const jobs = []
    const count = Math.min(params.pageSize, 10)
    
    for (let i = 0; i < count; i++) {
      const randomTags = tags.sort(() => 0.5 - Math.random()).slice(0, 3)
      
      jobs.push({
        id: Date.now() + i,
        title: jobTitles[Math.floor(Math.random() * jobTitles.length)],
        company: companies[Math.floor(Math.random() * companies.length)],
        location: locations[Math.floor(Math.random() * locations.length)],
        salary: salaries[Math.floor(Math.random() * salaries.length)],
        experience: experiences[Math.floor(Math.random() * experiences.length)],
        education: educations[Math.floor(Math.random() * educations.length)],
        tags: randomTags,
        publishTime: this.getRandomTime(),
        isFavorite: Math.random() > 0.7
      })
    }
    
    return jobs
  },

  // 生成随机时间
  getRandomTime() {
    const times = ['刚刚', '1小时前', '2小时前', '3小时前', '1天前', '2天前', '3天前']
    return times[Math.floor(Math.random() * times.length)]
  },

  // 刷新职位列表
  refreshJobs() {
    this.setData({
      page: 1,
      hasMore: true
    })
    this.loadJobs()
  },

  // 加载更多
  loadMore() {
    if (this.data.loading || !this.data.hasMore) return
    
    this.setData({
      page: this.data.page + 1
    })
    this.loadJobs()
  },

  // 导航到职位详情
  navigateToJobDetail(e) {
    const job = e.currentTarget.dataset.job
    wx.navigateTo({
      url: `/pages/job-detail/job-detail?id=${job.id}`
    })
  },

  // 切换收藏状态
  toggleFavorite(e) {
    const job = e.currentTarget.dataset.job
    
    if (job.isFavorite) {
      // 取消收藏
      JobAPI.unfavorite(job.id)
        .then((res) => {
          if (res.code === 0) {
            const jobs = this.data.jobs.map(item => {
              if (item.id === job.id) {
                return { ...item, isFavorite: false }
              }
              return item
            })
            
            this.setData({ jobs })
            
            wx.showToast({
              title: '已取消收藏',
              icon: 'success'
            })
          } else {
            wx.showToast({
              title: res.msg || '操作失败',
              icon: 'none'
            })
          }
        })
        .catch(() => {
          wx.showToast({
            title: '操作失败，请重试',
            icon: 'none'
          })
        })
    } else {
      // 添加收藏
      JobAPI.favorite(job.id)
        .then((res) => {
          if (res.code === 0) {
            const jobs = this.data.jobs.map(item => {
              if (item.id === job.id) {
                return { ...item, isFavorite: true }
              }
              return item
            })
            
            this.setData({ jobs })
            
            wx.showToast({
              title: '已收藏',
              icon: 'success'
            })
          } else {
            wx.showToast({
              title: res.msg || '操作失败',
              icon: 'none'
            })
          }
        })
        .catch(() => {
          wx.showToast({
            title: '操作失败，请重试',
            icon: 'none'
          })
        })
    }
  },

  // 投递职位
  applyJob(e) {
    const job = e.currentTarget.dataset.job
    
    // 检查是否已登录
    if (!app.globalData.token) {
      wx.showModal({
        title: '提示',
        content: '请先登录后再投递简历',
        confirmText: '去登录',
        success: (res) => {
          if (res.confirm) {
            wx.navigateTo({
              url: '/pages/login/login'
            })
          }
        }
      })
      return
    }
    
    // 检查是否有简历
    wx.showModal({
      title: '投递确认',
      content: `确定要投递到${job.company}的${job.title}职位吗？`,
      success: (res) => {
        if (res.confirm) {
          this.submitApplication(job)
        }
      }
    })
  },

  // 提交投递申请
  submitApplication(job) {
    wx.showLoading({
      title: '投递中...'
    })
    
    // 使用真实API请求
    JobAPI.apply(job.id, {
      resumeId: 1, // 默认简历ID，实际应该从用户简历中选择
      coverLetter: '' // 求职信，可选
    })
      .then((res) => {
        wx.hideLoading()
        
        if (res.code === 0) {
          wx.showToast({
            title: '投递成功',
            icon: 'success'
          })
          
          // 更新投递状态
          const jobs = this.data.jobs.map(item => {
            if (item.id === job.id) {
              return { ...item, applied: true }
            }
            return item
          })
          
          this.setData({ jobs })
        } else {
          wx.showToast({
            title: res.msg || '投递失败',
            icon: 'none'
          })
        }
      })
      .catch((err) => {
        wx.hideLoading()
        wx.showToast({
          title: '投递失败，请重试',
          icon: 'none'
        })
        console.error('投递失败:', err)
      })
  }
})
