// utils/util.js

// 格式化时间
const formatTime = (date, format = 'YYYY-MM-DD HH:mm:ss') => {
  if (!date) return ''
  
  const d = new Date(date)
  const year = d.getFullYear()
  const month = d.getMonth() + 1
  const day = d.getDate()
  const hour = d.getHours()
  const minute = d.getMinutes()
  const second = d.getSeconds()

  const formatNumber = n => {
    n = n.toString()
    return n[1] ? n : `0${n}`
  }

  return format
    .replace('YYYY', year)
    .replace('MM', formatNumber(month))
    .replace('DD', formatNumber(day))
    .replace('HH', formatNumber(hour))
    .replace('mm', formatNumber(minute))
    .replace('ss', formatNumber(second))
}

// 相对时间
const formatRelativeTime = (date) => {
  const now = new Date()
  const target = new Date(date)
  const diff = now - target

  const minute = 60 * 1000
  const hour = 60 * minute
  const day = 24 * hour
  const week = 7 * day
  const month = 30 * day
  const year = 365 * day

  if (diff < minute) {
    return '刚刚'
  } else if (diff < hour) {
    return `${Math.floor(diff / minute)}分钟前`
  } else if (diff < day) {
    return `${Math.floor(diff / hour)}小时前`
  } else if (diff < week) {
    return `${Math.floor(diff / day)}天前`
  } else if (diff < month) {
    return `${Math.floor(diff / week)}周前`
  } else if (diff < year) {
    return `${Math.floor(diff / month)}个月前`
  } else {
    return `${Math.floor(diff / year)}年前`
  }
}

// 格式化薪资
const formatSalary = (salary) => {
  if (!salary) return '面议'
  
  if (typeof salary === 'string') {
    return salary
  }
  
  if (typeof salary === 'number') {
    if (salary >= 10000) {
      return `${(salary / 10000).toFixed(1)}万`
    } else {
      return `${salary}K`
    }
  }
  
  return '面议'
}

// 格式化文件大小
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 B'
  
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 防抖函数
const debounce = (func, wait, immediate) => {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      timeout = null
      if (!immediate) func(...args)
    }
    const callNow = immediate && !timeout
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
    if (callNow) func(...args)
  }
}

// 节流函数
const throttle = (func, limit) => {
  let inThrottle
  return function() {
    const args = arguments
    const context = this
    if (!inThrottle) {
      func.apply(context, args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}

// 深拷贝
const deepClone = (obj) => {
  if (obj === null || typeof obj !== 'object') return obj
  if (obj instanceof Date) return new Date(obj.getTime())
  if (obj instanceof Array) return obj.map(item => deepClone(item))
  if (typeof obj === 'object') {
    const clonedObj = {}
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        clonedObj[key] = deepClone(obj[key])
      }
    }
    return clonedObj
  }
}

// 生成随机ID
const generateId = (length = 8) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let result = ''
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

// 验证手机号
const validatePhone = (phone) => {
  const phoneRegex = /^1[3-9]\d{9}$/
  return phoneRegex.test(phone)
}

// 验证邮箱
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// 验证身份证
const validateIdCard = (idCard) => {
  const idCardRegex = /(^\d{15}$)|(^\d{18}$)|(^\d{17}(\d|X|x)$)/
  return idCardRegex.test(idCard)
}

// 获取URL参数
const getUrlParams = (url) => {
  const params = {}
  const urlParts = url.split('?')
  if (urlParts.length > 1) {
    const queryString = urlParts[1]
    const pairs = queryString.split('&')
    pairs.forEach(pair => {
      const [key, value] = pair.split('=')
      params[decodeURIComponent(key)] = decodeURIComponent(value || '')
    })
  }
  return params
}

// 设置URL参数
const setUrlParams = (url, params) => {
  const urlObj = new URL(url)
  Object.keys(params).forEach(key => {
    urlObj.searchParams.set(key, params[key])
  })
  return urlObj.toString()
}

// 本地存储
const storage = {
  set: (key, value) => {
    try {
      wx.setStorageSync(key, value)
    } catch (error) {
      console.error('存储失败:', error)
    }
  },
  
  get: (key, defaultValue = null) => {
    try {
      const value = wx.getStorageSync(key)
      return value !== '' ? value : defaultValue
    } catch (error) {
      console.error('读取失败:', error)
      return defaultValue
    }
  },
  
  remove: (key) => {
    try {
      wx.removeStorageSync(key)
    } catch (error) {
      console.error('删除失败:', error)
    }
  },
  
  clear: () => {
    try {
      wx.clearStorageSync()
    } catch (error) {
      console.error('清空失败:', error)
    }
  }
}

// 显示提示
const showToast = (title, icon = 'none', duration = 2000) => {
  wx.showToast({
    title,
    icon,
    duration
  })
}

// 显示加载
const showLoading = (title = '加载中...', mask = true) => {
  wx.showLoading({
    title,
    mask
  })
}

// 隐藏加载
const hideLoading = () => {
  wx.hideLoading()
}

// 显示确认对话框
const showModal = (title, content, showCancel = true) => {
  return new Promise((resolve) => {
    wx.showModal({
      title,
      content,
      showCancel,
      success: (res) => {
        resolve(res.confirm)
      }
    })
  })
}

// 显示操作菜单
const showActionSheet = (itemList) => {
  return new Promise((resolve, reject) => {
    wx.showActionSheet({
      itemList,
      success: (res) => {
        resolve(res.tapIndex)
      },
      fail: reject
    })
  })
}

// 选择图片
const chooseImage = (count = 1, sizeType = ['original', 'compressed'], sourceType = ['album', 'camera']) => {
  return new Promise((resolve, reject) => {
    wx.chooseImage({
      count,
      sizeType,
      sourceType,
      success: resolve,
      fail: reject
    })
  })
}

// 预览图片
const previewImage = (current, urls) => {
  wx.previewImage({
    current,
    urls
  })
}

// 保存图片到相册
const saveImageToPhotosAlbum = (filePath) => {
  return new Promise((resolve, reject) => {
    wx.saveImageToPhotosAlbum({
      filePath,
      success: resolve,
      fail: reject
    })
  })
}

// 获取系统信息
const getSystemInfo = () => {
  return new Promise((resolve, reject) => {
    wx.getSystemInfo({
      success: resolve,
      fail: reject
    })
  })
}

// 获取网络状态
const getNetworkType = () => {
  return new Promise((resolve, reject) => {
    wx.getNetworkType({
      success: resolve,
      fail: reject
    })
  })
}

// 拨打电话
const makePhoneCall = (phoneNumber) => {
  wx.makePhoneCall({
    phoneNumber
  })
}

// 复制到剪贴板
const setClipboardData = (data) => {
  return new Promise((resolve, reject) => {
    wx.setClipboardData({
      data,
      success: resolve,
      fail: reject
    })
  })
}

// 获取剪贴板内容
const getClipboardData = () => {
  return new Promise((resolve, reject) => {
    wx.getClipboardData({
      success: resolve,
      fail: reject
    })
  })
}

module.exports = {
  formatTime,
  formatRelativeTime,
  formatSalary,
  formatFileSize,
  debounce,
  throttle,
  deepClone,
  generateId,
  validatePhone,
  validateEmail,
  validateIdCard,
  getUrlParams,
  setUrlParams,
  storage,
  showToast,
  showLoading,
  hideLoading,
  showModal,
  showActionSheet,
  chooseImage,
  previewImage,
  saveImageToPhotosAlbum,
  getSystemInfo,
  getNetworkType,
  makePhoneCall,
  setClipboardData,
  getClipboardData
}
