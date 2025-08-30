// utils/request.js
const app = getApp()

/**
 * 网络请求封装
 * @param {Object} options 请求配置
 * @returns {Promise} 请求结果
 */
function request(options) {
  return new Promise((resolve, reject) => {
    const { url, method = 'GET', data = {}, header = {} } = options
    
    // 添加默认请求头
    const defaultHeader = {
      'Content-Type': 'application/json'
    }
    
    // 添加认证token
    if (app.globalData.token) {
      defaultHeader['Authorization'] = `Bearer ${app.globalData.token}`
    }
    
    // 合并请求头
    const finalHeader = { ...defaultHeader, ...header }
    
    wx.request({
      url: `${app.globalData.baseUrl}${url}`,
      method,
      data,
      header: finalHeader,
      success: (res) => {
        if (res.statusCode === 200) {
          resolve(res.data)
        } else if (res.statusCode === 401) {
          // token过期，重新登录
          app.logout()
          wx.showToast({
            title: '登录已过期，请重新登录',
            icon: 'none'
          })
          reject(new Error('登录已过期'))
        } else {
          reject(new Error(res.data.message || '请求失败'))
        }
      },
      fail: (err) => {
        console.error('请求失败:', err)
        reject(new Error('网络请求失败'))
      }
    })
  })
}

/**
 * GET请求
 * @param {string} url 请求地址
 * @param {Object} params 请求参数
 * @returns {Promise} 请求结果
 */
function get(url, params = {}) {
  return request({
    url,
    method: 'GET',
    data: params
  })
}

/**
 * POST请求
 * @param {string} url 请求地址
 * @param {Object} data 请求数据
 * @returns {Promise} 请求结果
 */
function post(url, data = {}) {
  return request({
    url,
    method: 'POST',
    data
  })
}

/**
 * PUT请求
 * @param {string} url 请求地址
 * @param {Object} data 请求数据
 * @returns {Promise} 请求结果
 */
function put(url, data = {}) {
  return request({
    url,
    method: 'PUT',
    data
  })
}

/**
 * DELETE请求
 * @param {string} url 请求地址
 * @param {Object} data 请求数据
 * @returns {Promise} 请求结果
 */
function del(url, data = {}) {
  return request({
    url,
    method: 'DELETE',
    data
  })
}

/**
 * 上传文件
 * @param {string} url 上传地址
 * @param {string} filePath 文件路径
 * @param {string} name 文件字段名
 * @param {Object} formData 额外表单数据
 * @returns {Promise} 上传结果
 */
function uploadFile(url, filePath, name = 'file', formData = {}) {
  return new Promise((resolve, reject) => {
    const header = {}
    
    // 添加认证token
    if (app.globalData.token) {
      header['Authorization'] = `Bearer ${app.globalData.token}`
    }
    
    wx.uploadFile({
      url: `${app.globalData.baseUrl}${url}`,
      filePath,
      name,
      formData,
      header,
      success: (res) => {
        if (res.statusCode === 200) {
          try {
            const data = JSON.parse(res.data)
            resolve(data)
          } catch (e) {
            resolve(res.data)
          }
        } else {
          reject(new Error('上传失败'))
        }
      },
      fail: (err) => {
        console.error('上传失败:', err)
        reject(new Error('文件上传失败'))
      }
    })
  })
}

module.exports = {
  request,
  get,
  post,
  put,
  del,
  uploadFile
}
