// utils/api.js
const app = getApp()
const { API_CONFIG, USE_MOCK, MOCK_DATA } = require('../config/api.js')

// Mock数据响应函数
const getMockResponse = (url, method, data) => {
  console.log('Mock响应:', url, method, data)
  
  // 根据URL返回对应的Mock数据
  if (url.includes('/banner/list')) {
    return {
      success: true,
      code: 200,
      message: '获取成功',
      data: MOCK_DATA.banners
    }
  }
  
  if (url.includes('/job/recommend')) {
    return {
      success: true,
      code: 200,
      message: '获取成功',
      data: MOCK_DATA.jobs
    }
  }
  
  if (url.includes('/industry/hot')) {
    return {
      success: true,
      code: 200,
      message: '获取成功',
      data: [
        { id: 1, name: '互联网', icon: '/images/industry/internet.svg', jobCount: 5000 },
        { id: 2, name: '金融', icon: '/images/industry/finance.svg', jobCount: 3000 },
        { id: 3, name: '教育', icon: '/images/industry/education.svg', jobCount: 2000 }
      ]
    }
  }
  
  if (url.includes('/statistics/market')) {
    return {
      success: true,
      code: 200,
      message: '获取成功',
      data: MOCK_DATA.marketData
    }
  }
  
  // 默认响应
  return {
    success: true,
    code: 200,
    message: 'Mock数据',
    data: {}
  }
}

// 请求拦截器
const requestInterceptor = (config) => {
  // 添加token
  if (app.globalData.token) {
    config.header = {
      ...config.header,
      'Authorization': `Bearer ${app.globalData.token}`
    }
  }

  // 添加时间戳
  config.url = `${config.url}${config.url.includes('?') ? '&' : '?'}_t=${Date.now()}`

  return config
}

// 响应拦截器
const responseInterceptor = (response) => {
  const { statusCode, data } = response

  if (statusCode === 200) {
    return data
  } else if (statusCode === 401) {
    // 未授权，跳转登录
    app.logout()
    throw new Error('未授权，请重新登录')
  } else if (statusCode === 403) {
    throw new Error('权限不足')
  } else if (statusCode === 404) {
    throw new Error('请求的资源不存在')
  } else if (statusCode >= 500) {
    throw new Error('服务器错误')
  } else {
    throw new Error(data.message || '请求失败')
  }
}

// 通用请求方法
const request = (options) => {
  const { url, method = 'GET', data = {}, header = {}, retry = 0 } = options

  // Mock模式：直接返回Mock数据
  if (USE_MOCK) {
    console.log('Mock模式：返回模拟数据', url)
    return new Promise((resolve) => {
      setTimeout(() => {
        const mockResponse = getMockResponse(url, method, data)
        resolve(mockResponse)
      }, 100) // 模拟网络延迟
    })
  }

  const config = {
    url: `${API_CONFIG.baseUrl}${url}`,
    method,
    data,
    header: {
      'Content-Type': 'application/json',
      ...header
    },
    timeout: API_CONFIG.timeout
  }

  // 应用请求拦截器
  const interceptedConfig = requestInterceptor(config)

  return new Promise((resolve, reject) => {
    wx.request({
      ...interceptedConfig,
      success: (res) => {
        try {
          const result = responseInterceptor(res)
          resolve(result)
        } catch (error) {
          reject(error)
        }
      },
      fail: (error) => {
        console.error('请求失败:', error)
        
        // 重试机制
        if (retry < API_CONFIG.retryTimes) {
          console.log(`请求失败，第${retry + 1}次重试`)
          setTimeout(() => {
            request({ ...options, retry: retry + 1 })
              .then(resolve)
              .catch(reject)
          }, 1000 * (retry + 1))
        } else {
          reject(new Error('网络请求失败，请检查网络连接'))
        }
      }
    })
  })
}

// API方法封装
const api = {
  // 用户相关
  user: {
    // 登录
    login: (data) => request({
      url: '/auth/login',
      method: 'POST',
      data
    }),

    // 注册
    register: (data) => request({
      url: '/auth/register',
      method: 'POST',
      data
    }),

    // 发送验证码
    sendCode: (data) => request({
      url: '/auth/send-code',
      method: 'POST',
      data
    }),

    // 获取用户信息
    getInfo: () => request({
      url: '/user/info',
      method: 'GET'
    }),

    // 更新用户信息
    updateInfo: (data) => request({
      url: '/user/update',
      method: 'PUT',
      data
    }),

    // 修改密码
    changePassword: (data) => request({
      url: '/user/change-password',
      method: 'PUT',
      data
    })
  },

  // 职位相关
  job: {
    // 获取职位列表
    getList: (params) => request({
      url: '/job/list',
      method: 'GET',
      data: params
    }),

    // 获取职位详情
    getDetail: (id) => request({
      url: `/job/detail/${id}`,
      method: 'GET'
    }),

    // 推荐职位
    getRecommend: (params) => request({
      url: '/job/recommend',
      method: 'GET',
      data: params
    }),

    // 搜索职位
    search: (params) => request({
      url: '/job/search',
      method: 'GET',
      data: params
    }),

    // 投递简历
    apply: (data) => request({
      url: '/job/apply',
      method: 'POST',
      data
    }),

    // 收藏职位
    favorite: (data) => request({
      url: '/job/favorite',
      method: 'POST',
      data
    }),

    // 取消收藏
    unfavorite: (id) => request({
      url: `/job/unfavorite/${id}`,
      method: 'DELETE'
    })
  },

  // 简历相关
  resume: {
    // 获取简历列表
    getList: () => request({
      url: '/resume/list',
      method: 'GET'
    }),

    // 获取简历详情
    getDetail: (id) => request({
      url: `/resume/detail/${id}`,
      method: 'GET'
    }),

    // 创建简历
    create: (data) => request({
      url: '/resume/create',
      method: 'POST',
      data
    }),

    // 更新简历
    update: (data) => request({
      url: '/resume/update',
      method: 'PUT',
      data
    }),

    // 删除简历
    delete: (id) => request({
      url: `/resume/delete/${id}`,
      method: 'DELETE'
    }),

    // 上传附件
    upload: (filePath) => {
      return new Promise((resolve, reject) => {
        wx.uploadFile({
          url: `${API_CONFIG.baseUrl}/resume/upload`,
          filePath,
          name: 'file',
          header: {
            'Authorization': `Bearer ${app.globalData.token}`
          },
          success: (res) => {
            try {
              const data = JSON.parse(res.data)
              resolve(data)
            } catch (error) {
              reject(error)
            }
          },
          fail: reject
        })
      })
    }
  },

  // 聊天相关
  chat: {
    // 获取聊天列表
    getList: () => request({
      url: '/chat/list',
      method: 'GET'
    }),

    // 获取聊天记录
    getHistory: (chatId) => request({
      url: `/chat/history/${chatId}`,
      method: 'GET'
    }),

    // 发送消息
    sendMessage: (data) => request({
      url: '/chat/send',
      method: 'POST',
      data
    }),

    // AI聊天
    aiChat: (data) => request({
      url: '/chat/ai',
      method: 'POST',
      data
    })
  },

  // 统计分析
  statistics: {
    // 市场数据
    getMarketData: () => request({
      url: '/statistics/market',
      method: 'GET'
    }),

    // 个人数据
    getPersonalData: () => request({
      url: '/statistics/personal',
      method: 'GET'
    }),

    // 企业数据
    getEnterpriseData: () => request({
      url: '/statistics/enterprise',
      method: 'GET'
    })
  },

  // 企业服务
  enterprise: {
    // 获取企业服务列表
    getServices: () => request({
      url: '/enterprise/services',
      method: 'GET'
    }),

    // 获取服务详情
    getServiceDetail: (id) => request({
      url: `/enterprise/service/${id}`,
      method: 'GET'
    }),

    // 申请企业服务
    applyService: (data) => request({
      url: '/enterprise/apply',
      method: 'POST',
      data
    })
  },

  // 系统相关
  system: {
    // 获取配置
    getConfig: () => request({
      url: '/system/config',
      method: 'GET'
    }),

    // 获取版本信息
    getVersion: () => request({
      url: '/system/version',
      method: 'GET'
    }),

    // 反馈
    feedback: (data) => request({
      url: '/system/feedback',
      method: 'POST',
      data
    })
  }
}

module.exports = {
  request,
  api,
  API_CONFIG
}
