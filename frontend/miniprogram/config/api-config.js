// config/api-config.js

/**
 * API配置文件
 * 用于管理不同环境的API地址和配置
 */

// 环境配置
const ENV = {
  DEV: 'development',
  TEST: 'test', 
  PROD: 'production'
}

// 当前环境（可通过构建脚本或环境变量设置）
const CURRENT_ENV = ENV.DEV

// API配置
const API_CONFIGS = {
  // 开发环境
  [ENV.DEV]: {
    BASE_URL: 'http://localhost:8080',
    GATEWAY_URL: 'http://localhost:8080',
    USER_SERVICE_URL: 'http://localhost:9001',
    RESUME_SERVICE_URL: 'http://localhost:9002',
    POINTS_SERVICE_URL: 'http://localhost:9004',
    STATISTICS_SERVICE_URL: 'http://localhost:9005',
    STORAGE_SERVICE_URL: 'http://localhost:9003',
    ENTERPRISE_SERVICE_URL: 'http://localhost:8002',
    OPEN_SERVICE_URL: 'http://localhost:9006',
    BLOCKCHAIN_SERVICE_URL: 'http://localhost:9007',
    TIMEOUT: 10000,
    RETRY_TIMES: 3,
    RETRY_DELAY: 1000
  },

  // 测试环境
  [ENV.TEST]: {
    BASE_URL: 'https://test-api.jobfirst.com',
    GATEWAY_URL: 'https://test-api.jobfirst.com',
    USER_SERVICE_URL: 'https://test-user.jobfirst.com',
    RESUME_SERVICE_URL: 'https://test-resume.jobfirst.com',
    POINTS_SERVICE_URL: 'https://test-points.jobfirst.com',
    STATISTICS_SERVICE_URL: 'https://test-statistics.jobfirst.com',
    STORAGE_SERVICE_URL: 'https://test-storage.jobfirst.com',
    ENTERPRISE_SERVICE_URL: 'https://test-enterprise.jobfirst.com',
    OPEN_SERVICE_URL: 'https://test-open.jobfirst.com',
    BLOCKCHAIN_SERVICE_URL: 'https://test-blockchain.jobfirst.com',
    TIMEOUT: 15000,
    RETRY_TIMES: 3,
    RETRY_DELAY: 2000
  },

  // 生产环境
  [ENV.PROD]: {
    BASE_URL: 'https://api.jobfirst.com',
    GATEWAY_URL: 'https://api.jobfirst.com',
    USER_SERVICE_URL: 'https://user.jobfirst.com',
    RESUME_SERVICE_URL: 'https://resume.jobfirst.com',
    POINTS_SERVICE_URL: 'https://points.jobfirst.com',
    STATISTICS_SERVICE_URL: 'https://statistics.jobfirst.com',
    STORAGE_SERVICE_URL: 'https://storage.jobfirst.com',
    ENTERPRISE_SERVICE_URL: 'https://enterprise.jobfirst.com',
    OPEN_SERVICE_URL: 'https://open.jobfirst.com',
    BLOCKCHAIN_SERVICE_URL: 'https://blockchain.jobfirst.com',
    TIMEOUT: 20000,
    RETRY_TIMES: 2,
    RETRY_DELAY: 3000
  }
}

// 获取当前环境配置
const getCurrentConfig = () => {
  return API_CONFIGS[CURRENT_ENV] || API_CONFIGS[ENV.DEV]
}

// API路径配置
const API_PATHS = {
  // 用户认证
  AUTH: {
    LOGIN: '/api/v1/user/auth/login',
    CHECK: '/api/v1/user/auth/check',
    LOGOUT: '/api/v1/user/auth/logout',
    PHONE: '/api/v1/user/auth/phone',
    IDKEY: '/api/v1/user/auth/idkey',
    CERTIFICATION: '/api/v1/user/auth/certification',
    UNSUBSCRIBE: '/api/v1/user/auth/unsubscribe',
    MY_IDKEY: '/api/v1/user/auth/myidkey'
  },

  // 公开API
  PUBLIC: {
    BANNERS: '/api/v1/public/home/banners',
    NOTIFICATIONS: '/api/v1/public/home/notifications',
    LOGIN: '/api/v1/public/authentication/login',
    CHECK_AUTH: '/api/v1/public/authentication/check',
    GET_USER_PHONE: '/api/v1/public/authentication/getUserPhone',
    GET_USER_ID_KEY: '/api/v1/public/authentication/getUserIdKey',
    REGISTER: '/api/v1/public/mine/register',
    REGISTER_CODE: '/api/v1/public/mine/register/code',
    CHANGE_PASSWORD_CODE: '/api/v1/public/mine/password/change/code',
    RESET_PASSWORD: '/api/v1/public/mine/password/reset',
    RESUME_LIST: '/api/v1/public/mine/resume/list',
    RESUME_DETAIL: '/api/v1/public/mine/resume/detail',
    CREATE_RESUME: '/api/v1/public/mine/resume/create',
    UPDATE_RESUME: '/api/v1/public/mine/resume/update',
    DELETE_RESUME: '/api/v1/public/mine/resume/delete',
    DOWNLOAD_RESUME: '/api/v1/public/mine/resume/download',
    APPROVE_HISTORY: '/api/v1/public/mine/approve/history',
    VIEW_HISTORY: '/api/v1/public/mine/view/history',
    CERTIFICATION: '/api/v1/public/mine/certification',
    UPDATE_AVATAR: '/api/v1/public/mine/avatar',
    APPROVE_LIST: '/api/v1/public/approve/list',
    HANDLE_APPROVE: '/api/v1/public/approve/handle',
    CHAT_USUAL: '/api/v1/public/chat/usual',
    CHAT: '/api/v1/public/chat/chat'
  },

  // 职位相关
  JOB: {
    SEARCH: '/open/job/search',
    DETAIL: '/open/job/detail',
    RECOMMEND: '/open/job/recommend',
    HOT: '/open/job/hot',
    NEARBY: '/open/job/nearby',
    CATEGORIES: '/open/job/categories',
    BY_CATEGORY: '/open/job/category',
    APPLY: '/open/job/apply',
    FAVORITE: '/open/job/favorite',
    FAVORITES: '/open/job/favorites',
    APPLICATIONS: '/open/job/applications'
  },

  // 企业相关
  COMPANY: {
    LIST: '/open/company/list',
    DETAIL: '/open/company/detail',
    RECOMMEND: '/open/company/recommend',
    SEARCH: '/open/company/search',
    JOBS: '/open/company/jobs'
  },

  // 简历相关
  RESUME: {
    LIST: '/resume/list',
    DETAIL: '/resume/detail',
    CREATE: '/resume/create',
    UPDATE: '/resume/update',
    DELETE: '/resume/delete',
    TEMPLATES: '/resume/templates',
    UPLOAD: '/resume/upload',
    PREVIEW: '/resume/preview',
    EXPORT: '/resume/export'
  },

  // 聊天相关
  CHAT: {
    LIST: '/chat/list',
    DETAIL: '/chat/detail',
    SEND_MESSAGE: '/chat/message',
    MESSAGES: '/chat/messages',
    MARK_READ: '/chat/read',
    DELETE: '/chat/delete',
    CLEAR_HISTORY: '/chat/history'
  },

  // 用户相关
  USER: {
    PROFILE: '/api/v1/users/profile',
    UPDATE_PROFILE: '/api/v1/users/profile',
    DELETE: '/api/v1/users',
    STATS: '/api/v1/users/stats',
    SETTINGS: '/api/v1/users/settings',
    UPDATE_SETTINGS: '/api/v1/users/settings'
  },

  // 积分相关
  POINTS: {
    BALANCE: '/points/balance',
    HISTORY: '/points/history',
    RULES: '/points/rules',
    EXCHANGE: '/points/exchange',
    TRANSFER: '/points/transfer'
  },

  // 统计相关
  STATISTICS: {
    OVERVIEW: '/statistics/overview',
    USERS: '/statistics/users',
    RESUMES: '/statistics/resumes',
    JOBS: '/statistics/jobs',
    COMPANIES: '/statistics/companies'
  },

  // 资源相关
  RESOURCE: {
    UPLOAD: '/api/v1/resources/upload',
    URLS: '/api/v1/resources/urls',
    URL_DETAIL: '/api/v1/resources/urls',
    DELETE: '/api/v1/resources',
    UPDATE: '/api/v1/resources',
    DICT_TYPES: '/api/v1/resources/dict/types',
    DICT_DATA: '/api/v1/resources/dict/data',
    SCHOOLS: '/api/v1/resources/schools'
  },

  // 系统相关
  SYSTEM: {
    VERSION: '/resource/version',
    HEALTH: '/health',
    CONFIG: '/api/v1/system/config',
    FEEDBACK: '/api/v1/system/feedback',
    ABOUT: '/api/v1/system/about'
  }
}

// 响应码配置
const RESPONSE_CODES = {
  SUCCESS: 0,
  ERROR: 500,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  VALIDATION_ERROR: 422,
  RATE_LIMIT: 429,
  SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503
}

// 错误消息配置
const ERROR_MESSAGES = {
  [RESPONSE_CODES.UNAUTHORIZED]: '登录已过期，请重新登录',
  [RESPONSE_CODES.FORBIDDEN]: '没有权限访问该资源',
  [RESPONSE_CODES.NOT_FOUND]: '请求的资源不存在',
  [RESPONSE_CODES.VALIDATION_ERROR]: '请求参数错误',
  [RESPONSE_CODES.RATE_LIMIT]: '请求过于频繁，请稍后再试',
  [RESPONSE_CODES.SERVER_ERROR]: '服务器内部错误',
  [RESPONSE_CODES.SERVICE_UNAVAILABLE]: '服务暂时不可用',
  NETWORK_ERROR: '网络连接失败，请检查网络设置',
  TIMEOUT_ERROR: '请求超时，请稍后重试',
  UNKNOWN_ERROR: '未知错误，请稍后重试'
}

// 请求头配置
const DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-Requested-With': 'XMLHttpRequest'
}

// 导出配置
module.exports = {
  ENV,
  CURRENT_ENV,
  getCurrentConfig,
  API_PATHS,
  RESPONSE_CODES,
  ERROR_MESSAGES,
  DEFAULT_HEADERS
}
