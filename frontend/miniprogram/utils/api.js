// utils/api.js

// 强制锁定API地址（覆盖所有可能的配置）
const BASE_API_URL = 'http://localhost:8080'

// API配置
const API_CONFIG = {
  BASE_URL: BASE_API_URL,
  SUCCESS_CODE: 200,
  ERROR_CODE: 500,
  TOKEN_KEY: 'accessToken',
  TOKEN_PREFIX: 'Bearer '
}

// 获取API版本
function getAPIVersion() {
  try {
    const { upgradeManager } = require('../config/upgrade-config.js')  // 修复路径
    return upgradeManager.getCurrentAPIVersion()
  } catch (error) {
    console.log('Using default API version: v1')
    return 'v1'
  }
}

// 获取API基础URL
function getAPIBaseUrl() {
  // 最终强制锁定
  const baseUrl = BASE_API_URL
  const version = getAPIVersion()
  return version === 'v2' ? `${baseUrl}/api/v2` : `${baseUrl}/api/v1`
}

// 获取请求头
function getHeaders() {
  const headers = {
    'Content-Type': 'application/json',
    'API-Version': getAPIVersion()
  }
  
  // 添加认证token
  const token = wx.getStorageSync(API_CONFIG.TOKEN_KEY)
  if (token) {
    headers['Authorization'] = API_CONFIG.TOKEN_PREFIX + token
  }
  
  return headers
}

// 强制重写请求方法
function request(url, options = {}) {
  console.log('[API请求]', url, '参数:', JSON.stringify(options));
  return new Promise((resolve, reject) => {
    // 使用配置的基础URL
    const targetUrl = `${BASE_API_URL}${url.startsWith('/api') ? '' : '/api/v1'}${url}`
    
    // 检查是否有8081端口的请求
    if (targetUrl.includes(':8081')) {
      console.warn('⚠️ API模块检测到8081端口请求，正在修正为8080端口:', targetUrl)
    }
    
    const requestOptions = {
      url: targetUrl,
      method: options.method || 'GET',
      data: options.data || {},
      header: { ...getHeaders(), ...options.header },
      success: (res) => {
        if (res.statusCode === API_CONFIG.SUCCESS_CODE) {
          resolve(res.data)
        } else {
          // 检查是否需要降级
          // 临时禁用降级逻辑
          console.log('API请求失败:', res.statusCode)
          reject(res)
        }
      },
      fail: (err) => {
        console.error('API请求失败:', err)
        reject(err)
      }
    }
    
    wx.request(requestOptions)
  })
}

// 认证相关API
const AuthAPI = {
  // 微信登录
  wxLogin: (data) => request('/user/wxLogin', {
    method: 'POST',
    data
  }),
  
  // 用户登录
  login: (data) => request('/user/login', {
    method: 'POST',
    data
  }),
  
  // 用户注册
  register: (data) => request('/user/register', {
    method: 'POST',
    data
  }),
  
  // 检查登录状态
  checkLogin: () => request('/user/auth/check'),
  
  // 获取用户手机号
  getUserPhone: () => request('/user/phone'),
  
  // 登出
  logout: () => request('/user/auth/logout', {
    method: 'POST'
  })
}

// 公开API
const PublicAPI = {
  // 获取首页轮播图
  getBanners: () => request('/banners/'),
  
  // 获取用户信息
  getUserInfo: () => request('/user/info'),
  
  // 获取用户手机号
  getUserPhone: () => request('/user/phone'),
  
  // 获取简历列表
  getResumeList: () => request('/resume/list'),
  
  // 获取企业列表
  getCompanies: () => request('/companies/'),
  
  // 获取企业详情
  getCompanyDetail: (id) => request(`/companies/${id}`)
}

// 职位相关API
const JobAPI = {
  // 获取职位列表
  getJobs: (params = {}) => {
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    return request(`/jobs/?${queryString}`)
  },
  
  // 获取职位详情
  getJobDetail: (id) => request(`/jobs/${id}`),
  
  // 搜索职位
  searchJobs: (params = {}) => {
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    return request(`/jobs/search?${queryString}`)
  },
  
  // 申请职位
  apply: (data) => request('/job/apply', {
    method: 'POST',
    data
  }),
  
  // 收藏职位
  favorite: (data) => request('/job/collect', {
    method: 'POST',
    data
  }),
  
  // 取消收藏
  unfavorite: (data) => request('/job/cancelCollect', {
    method: 'POST',
    data
  }),
  
  // 获取收藏列表
  getFavorites: () => request('/job/collectList'),
  
  // 获取申请列表
  getApplications: () => request('/job/applyList')
}

// 企业相关API
const CompanyAPI = {
  // 获取企业列表
  getCompanies: () => request('/companies/'),
  
  // 获取企业详情
  getCompanyDetail: (id) => request(`/companies/${id}`),
  
  // 获取推荐企业
  getRecommendCompanies: () => request('/companies/')
}

// 简历相关API
const ResumeAPI = {
  // 获取简历列表
  getResumeList: () => request('/resume/list'),
  
  // 获取简历详情
  getResumeDetail: (id) => request(`/resume/${id}`),
  
  // 创建简历
  createResume: (data) => request('/resume/create', {
    method: 'POST',
    data
  }),
  
  // 更新简历
  updateResume: (id, data) => request(`/resume/${id}`, {
    method: 'PUT',
    data
  }),
  
  // 删除简历
  deleteResume: (id) => request(`/resume/${id}`, {
    method: 'DELETE'
  })
}

// 聊天相关API
const ChatAPI = {
  // 获取聊天会话列表
  getSessions: () => request('/chat/sessions'),
  
  // 获取聊天消息
  getMessages: (sessionId, params = {}) => {
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    return request(`/chat/sessions/${sessionId}/messages?${queryString}`)
  },
  
  // 发送消息
  sendMessage: (sessionId, data) => request(`/chat/sessions/${sessionId}/messages`, {
    method: 'POST',
    data
  }),
  
  // 标记消息已读
  markMessageRead: (sessionId, messageId) => request(`/chat/sessions/${sessionId}/messages/${messageId}/read`, {
    method: 'PUT'
  }),
  
  // 创建聊天会话
  createSession: (data) => request('/chat/sessions', {
    method: 'POST',
    data
  })
}

// 用户相关API
const UserAPI = {
  // 获取用户信息
  getInfo: () => request('/user/info'),
  
  // 更新用户信息
  updateInfo: (data) => request('/user/update', {
    method: 'PUT',
    data
  }),
  
  // 更新头像
  updateAvatar: (data) => request('/mine/avatar', {
    method: 'PUT',
    data
  })
}

// 积分相关API
const PointsAPI = {
  // 获取积分余额
  getBalance: () => request('/points/balance'),
  
  // 获取积分记录
  getRecords: (params = {}) => {
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    return request(`/points/records?${queryString}`)
  },
  
  // 获取积分规则
  getRules: () => request('/points/rules'),
  
  // 积分兑换
  exchange: (data) => request('/points/exchange', {
    method: 'POST',
    data
  }),
  
  // 获取兑换历史
  getExchangeHistory: (params = {}) => {
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    return request(`/points/exchanges?${queryString}`)
  }
}

// 通知相关API
const NotificationAPI = {
  // 获取通知列表
  getNotifications: (params = {}) => {
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    return request(`/notifications?${queryString}`)
  },

  // 获取通知详情
  getNotificationDetail: (id) => request(`/notifications/${id}`),

  // 标记通知已读
  markNotificationRead: (id) => request(`/notifications/${id}/read`, {
    method: 'PUT'
  }),

  // 标记所有通知已读
  markAllNotificationsRead: (params = {}) => {
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    return request(`/notifications/read-all?${queryString}`, {
      method: 'PUT'
    })
  },

  // 获取通知设置
  getNotificationSettings: () => request('/notifications/settings'),

  // 更新通知设置
  updateNotificationSettings: (data) => request('/notifications/settings', {
    method: 'PUT',
    data
  }),

  // 获取通知模板
  getNotificationTemplates: () => request('/notifications/templates'),

  // 发送通知
  sendNotification: (data) => request('/notifications/send', {
    method: 'POST',
    data
  })
}

// 统计相关API
const StatisticsAPI = {
  // 获取用户统计
  getUserStats: () => request('/mine/info'),
  
  // 获取浏览历史
  getViewHistory: () => request('/mine/view/history'),
  
  // 获取审批历史
  getApproveHistory: () => request('/mine/approve/history')
}

// 资源相关API
const ResourceAPI = {
  // 文件上传
  upload: (filePath) => {
    return new Promise((resolve, reject) => {
      wx.uploadFile({
        url: getAPIBaseUrl() + '/common/upload',
        filePath: filePath,
        name: 'file',
        header: getHeaders(),
        success: (res) => {
          const data = JSON.parse(res.data)
          resolve(data)
        },
        fail: reject
      })
    })
  }
}

// 系统相关API
const SystemAPI = {
  // 获取系统配置
  getConfig: () => request('/common/config'),
  
  // 获取地区列表
  getRegions: () => request('/common/region'),
  
  // 获取分类列表
  getCategories: () => request('/common/category')
}

module.exports = {
  API_CONFIG,
  request,
  getAPIVersion,
  getAPIBaseUrl,
  getHeaders,
  AuthAPI,
  PublicAPI,
  JobAPI,
  CompanyAPI,
  ResumeAPI,
  ChatAPI,
  UserAPI,
  PointsAPI,
  NotificationAPI,
  StatisticsAPI,
  ResourceAPI,
  SystemAPI
}
