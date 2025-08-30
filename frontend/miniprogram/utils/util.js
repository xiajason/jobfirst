// utils/util.js

/**
 * 格式化时间
 * @param {Date|string|number} date 日期
 * @param {string} format 格式化字符串
 * @returns {string} 格式化后的时间
 */
function formatTime(date, format = 'YYYY-MM-DD HH:mm:ss') {
  const d = new Date(date)
  
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const hour = String(d.getHours()).padStart(2, '0')
  const minute = String(d.getMinutes()).padStart(2, '0')
  const second = String(d.getSeconds()).padStart(2, '0')
  
  return format
    .replace('YYYY', year)
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hour)
    .replace('mm', minute)
    .replace('ss', second)
}

/**
 * 获取相对时间
 * @param {Date|string|number} date 日期
 * @returns {string} 相对时间字符串
 */
function getRelativeTime(date) {
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

/**
 * 防抖函数
 * @param {Function} func 要防抖的函数
 * @param {number} wait 等待时间
 * @returns {Function} 防抖后的函数
 */
function debounce(func, wait = 300) {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout)
      func(...args)
    }
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}

/**
 * 节流函数
 * @param {Function} func 要节流的函数
 * @param {number} limit 限制时间
 * @returns {Function} 节流后的函数
 */
function throttle(func, limit = 300) {
  let inThrottle
  return function executedFunction(...args) {
    if (!inThrottle) {
      func.apply(this, args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}

/**
 * 深拷贝对象
 * @param {*} obj 要拷贝的对象
 * @returns {*} 拷贝后的对象
 */
function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') {
    return obj
  }
  
  if (obj instanceof Date) {
    return new Date(obj.getTime())
  }
  
  if (obj instanceof Array) {
    return obj.map(item => deepClone(item))
  }
  
  if (typeof obj === 'object') {
    const cloned = {}
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        cloned[key] = deepClone(obj[key])
      }
    }
    return cloned
  }
}

/**
 * 生成随机ID
 * @param {number} length ID长度
 * @returns {string} 随机ID
 */
function generateId(length = 8) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let result = ''
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

/**
 * 验证手机号
 * @param {string} phone 手机号
 * @returns {boolean} 是否有效
 */
function validatePhone(phone) {
  const reg = /^1[3-9]\d{9}$/
  return reg.test(phone)
}

/**
 * 验证邮箱
 * @param {string} email 邮箱
 * @returns {boolean} 是否有效
 */
function validateEmail(email) {
  const reg = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return reg.test(email)
}

/**
 * 验证身份证号
 * @param {string} idCard 身份证号
 * @returns {boolean} 是否有效
 */
function validateIdCard(idCard) {
  const reg = /(^\d{15}$)|(^\d{18}$)|(^\d{17}(\d|X|x)$)/
  return reg.test(idCard)
}

/**
 * 格式化文件大小
 * @param {number} bytes 字节数
 * @returns {string} 格式化后的文件大小
 */
function formatFileSize(bytes) {
  if (bytes === 0) return '0 B'
  
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

/**
 * 获取文件扩展名
 * @param {string} filename 文件名
 * @returns {string} 文件扩展名
 */
function getFileExtension(filename) {
  return filename.slice((filename.lastIndexOf('.') - 1 >>> 0) + 2)
}

/**
 * 检查是否为图片文件
 * @param {string} filename 文件名
 * @returns {boolean} 是否为图片
 */
function isImageFile(filename) {
  const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
  const ext = getFileExtension(filename).toLowerCase()
  return imageExts.includes(ext)
}

/**
 * 检查是否为视频文件
 * @param {string} filename 文件名
 * @returns {boolean} 是否为视频
 */
function isVideoFile(filename) {
  const videoExts = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm']
  const ext = getFileExtension(filename).toLowerCase()
  return videoExts.includes(ext)
}

/**
 * 获取系统信息
 * @returns {Object} 系统信息
 */
function getSystemInfo() {
  return new Promise((resolve, reject) => {
    wx.getSystemInfo({
      success: resolve,
      fail: reject
    })
  })
}

/**
 * 显示加载提示
 * @param {string} title 提示文字
 */
function showLoading(title = '加载中...') {
  wx.showLoading({
    title,
    mask: true
  })
}

/**
 * 隐藏加载提示
 */
function hideLoading() {
  wx.hideLoading()
}

/**
 * 显示成功提示
 * @param {string} title 提示文字
 * @param {number} duration 显示时长
 */
function showSuccess(title, duration = 2000) {
  wx.showToast({
    title,
    icon: 'success',
    duration
  })
}

/**
 * 显示错误提示
 * @param {string} title 提示文字
 * @param {number} duration 显示时长
 */
function showError(title, duration = 2000) {
  wx.showToast({
    title,
    icon: 'error',
    duration
  })
}

/**
 * 显示警告提示
 * @param {string} title 提示文字
 * @param {number} duration 显示时长
 */
function showWarning(title, duration = 2000) {
  wx.showToast({
    title,
    icon: 'none',
    duration
  })
}

module.exports = {
  formatTime,
  getRelativeTime,
  debounce,
  throttle,
  deepClone,
  generateId,
  validatePhone,
  validateEmail,
  validateIdCard,
  formatFileSize,
  getFileExtension,
  isImageFile,
  isVideoFile,
  getSystemInfo,
  showLoading,
  hideLoading,
  showSuccess,
  showError,
  showWarning
}
