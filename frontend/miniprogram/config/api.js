// config/api.js
// API配置文件

// 环境配置
const ENV = {
  development: {
    baseUrl: 'http://localhost:3000',
    timeout: 10000,
    retryTimes: 3
  },
  production: {
    baseUrl: 'https://api.adirp.com',
    timeout: 10000,
    retryTimes: 3
  },
  mock: {
    baseUrl: '',
    timeout: 1000,
    retryTimes: 0
  }
}

// 当前环境（可以通过构建脚本或环境变量设置）
const CURRENT_ENV = 'mock'

// 导出当前环境的配置
const API_CONFIG = ENV[CURRENT_ENV]

// 是否启用Mock数据
const USE_MOCK = CURRENT_ENV === 'mock'

// API端点配置
const API_ENDPOINTS = {
  // 用户相关
  user: {
    login: '/user/login',
    register: '/user/register',
    sendCode: '/user/sendCode',
    info: '/user/info',
    validate: '/user/validate',
    updateInfo: '/user/updateInfo',
    changePassword: '/user/changePassword',
    logout: '/user/logout'
  },
  
  // 职位相关
  job: {
    list: '/job/list',
    detail: '/job/detail',
    recommend: '/job/recommend',
    search: '/job/search',
    apply: '/job/apply',
    favorite: '/job/favorite',
    unfavorite: '/job/unfavorite'
  },
  
  // 简历相关
  resume: {
    list: '/resume/list',
    detail: '/resume/detail',
    create: '/resume/create',
    update: '/resume/update',
    delete: '/resume/delete',
    upload: '/resume/upload'
  },
  
  // 聊天相关
  chat: {
    list: '/chat/list',
    history: '/chat/history',
    sendMessage: '/chat/sendMessage',
    aiChat: '/chat/aiChat'
  },
  
  // 统计数据
  statistics: {
    market: '/statistics/market',
    personal: '/statistics/personal',
    enterprise: '/statistics/enterprise'
  },
  
  // 企业服务
  enterprise: {
    services: '/enterprise/services',
    serviceDetail: '/enterprise/serviceDetail',
    applyService: '/enterprise/applyService'
  },
  
  // 系统相关
  system: {
    config: '/system/config',
    version: '/system/version',
    feedback: '/system/feedback'
  },
  
  // 其他
  banner: {
    list: '/banner/list'
  },
  
  industry: {
    hot: '/industry/hot'
  }
}

// Mock数据配置
const MOCK_DATA = {
  banners: [
    {
      id: 1,
      image: '/images/banner1.svg',
      title: '智能招聘，连接未来',
      link: '/pages/jobs/jobs'
    },
    {
      id: 2,
      image: '/images/banner2.svg',
      title: 'AI助手，求职更轻松',
      link: '/pages/chat/ai'
    }
  ],
  
  jobs: [
    {
      id: 1,
      title: '前端开发工程师',
      company: '腾讯科技',
      salary: '15K-25K',
      location: '深圳',
      tags: ['React', 'Vue', 'JavaScript']
    },
    {
      id: 2,
      title: '后端开发工程师',
      company: '阿里巴巴',
      salary: '20K-35K',
      location: '杭州',
      tags: ['Java', 'Spring', 'MySQL']
    },
    {
      id: 3,
      title: '产品经理',
      company: '字节跳动',
      salary: '25K-40K',
      location: '北京',
      tags: ['产品设计', '用户研究', '数据分析']
    }
  ],
  
  marketData: {
    jobCount: '10,000+',
    companyCount: '500+',
    avgSalary: '15K',
    growthRate: '12%'
  }
}

module.exports = {
  API_CONFIG,
  API_ENDPOINTS,
  USE_MOCK,
  MOCK_DATA,
  CURRENT_ENV
}
