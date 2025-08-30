// test/api-test.js

/**
 * API接口测试脚本
 * 用于测试小程序与后端服务的接口连接
 */

const { getCurrentConfig, API_PATHS, RESPONSE_CODES } = require('../config/api-config.js')

/**
 * API测试类
 */
class APITester {
  constructor() {
    this.config = getCurrentConfig()
    this.testResults = []
    this.currentTest = 0
    this.totalTests = 0
  }

  /**
   * 运行所有测试
   */
  async runAllTests() {
    console.log('🚀 开始API接口测试...')
    console.log(`📡 测试环境: ${this.config.BASE_URL}`)
    console.log('=' * 50)

    const tests = [
      // 系统健康检查
      { name: '系统健康检查', test: () => this.testHealth() },
      
      // 公开接口测试
      { name: '获取轮播图', test: () => this.testGetBanners() },
      { name: '获取通知', test: () => this.testGetNotifications() },
      { name: '获取服务版本', test: () => this.testGetVersion() },
      
      // 职位相关接口
      { name: '职位搜索', test: () => this.testJobSearch() },
      { name: '获取推荐职位', test: () => this.testGetRecommendJobs() },
      { name: '获取热门职位', test: () => this.testGetHotJobs() },
      
      // 企业相关接口
      { name: '获取推荐企业', test: () => this.testGetRecommendCompanies() },
      { name: '企业搜索', test: () => this.testCompanySearch() },
      
      // 用户认证接口
      { name: '用户登录', test: () => this.testUserLogin() },
      { name: '检查登录状态', test: () => this.testCheckLogin() },
      
      // 简历相关接口
      { name: '获取简历列表', test: () => this.testGetResumeList() },
      { name: '获取简历模板', test: () => this.testGetResumeTemplates() },
      
      // 积分相关接口
      { name: '获取积分余额', test: () => this.testGetPointsBalance() },
      { name: '获取积分规则', test: () => this.testGetPointsRules() },
      
      // 统计相关接口
      { name: '获取统计概览', test: () => this.testGetStatisticsOverview() },
      { name: '获取用户统计', test: () => this.testGetUserStatistics() }
    ]

    this.totalTests = tests.length

    for (const test of tests) {
      this.currentTest++
      console.log(`\n📋 测试 ${this.currentTest}/${this.totalTests}: ${test.name}`)
      
      try {
        const result = await test.test()
        this.testResults.push({
          name: test.name,
          success: true,
          result
        })
        console.log(`✅ ${test.name} - 通过`)
      } catch (error) {
        this.testResults.push({
          name: test.name,
          success: false,
          error: error.message
        })
        console.log(`❌ ${test.name} - 失败: ${error.message}`)
      }
    }

    this.printTestSummary()
  }

  /**
   * 发送HTTP请求
   */
  async request(url, options = {}) {
    const fullUrl = `${this.config.BASE_URL}${url}`
    
    const defaultOptions = {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      timeout: this.config.TIMEOUT
    }

    const requestOptions = { ...defaultOptions, ...options }

    return new Promise((resolve, reject) => {
      wx.request({
        url: fullUrl,
        method: requestOptions.method,
        data: requestOptions.data,
        header: requestOptions.headers,
        timeout: requestOptions.timeout,
        success: (res) => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(res.data)
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${res.data?.msg || '请求失败'}`))
          }
        },
        fail: (err) => {
          reject(new Error(`网络错误: ${err.errMsg || '未知错误'}`))
        }
      })
    })
  }

  /**
   * 测试系统健康检查
   */
  async testHealth() {
    const response = await this.request(API_PATHS.SYSTEM.HEALTH)
    if (response.status !== 'healthy') {
      throw new Error('系统健康检查失败')
    }
    return response
  }

  /**
   * 测试获取轮播图
   */
  async testGetBanners() {
    const response = await this.request(API_PATHS.PUBLIC.BANNERS)
    if (response.code !== 200) {
      throw new Error(`获取轮播图失败: ${response.message}`)
    }
    if (!Array.isArray(response.data)) {
      throw new Error('轮播图数据格式错误')
    }
    return response.data
  }

  /**
   * 测试获取通知
   */
  async testGetNotifications() {
    const response = await this.request(API_PATHS.PUBLIC.NOTIFICATIONS)
    if (response.code !== 200) {
      throw new Error(`获取通知失败: ${response.message}`)
    }
    if (!Array.isArray(response.data)) {
      throw new Error('通知数据格式错误')
    }
    return response.data
  }

  /**
   * 测试获取服务版本
   */
  async testGetVersion() {
    const response = await this.request(API_PATHS.SYSTEM.VERSION)
    if (response.code !== 0) {
      throw new Error(`获取版本失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试职位搜索
   */
  async testJobSearch() {
    const params = {
      page: 1,
      pageSize: 10,
      keyword: '前端'
    }
    
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    
    const response = await this.request(`${API_PATHS.JOB.SEARCH}?${queryString}`)
    if (response.code !== 0) {
      throw new Error(`职位搜索失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取推荐职位
   */
  async testGetRecommendJobs() {
    const response = await this.request(API_PATHS.JOB.RECOMMEND)
    if (response.code !== 0) {
      throw new Error(`获取推荐职位失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取热门职位
   */
  async testGetHotJobs() {
    const response = await this.request(API_PATHS.JOB.HOT)
    if (response.code !== 0) {
      throw new Error(`获取热门职位失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取推荐企业
   */
  async testGetRecommendCompanies() {
    const response = await this.request(API_PATHS.COMPANY.RECOMMEND)
    if (response.code !== 0) {
      throw new Error(`获取推荐企业失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试企业搜索
   */
  async testCompanySearch() {
    const params = {
      page: 1,
      pageSize: 10,
      keyword: '科技'
    }
    
    const queryString = Object.keys(params)
      .map(key => `${key}=${encodeURIComponent(params[key])}`)
      .join('&')
    
    const response = await this.request(`${API_PATHS.COMPANY.SEARCH}?${queryString}`)
    if (response.code !== 0) {
      throw new Error(`企业搜索失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试用户登录
   */
  async testUserLogin() {
    const loginData = {
      code: 'test_code_123'
    }
    
    const response = await this.request(API_PATHS.AUTH.LOGIN, {
      method: 'POST',
      data: loginData
    })
    
    if (response.code !== 0) {
      throw new Error(`用户登录失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试检查登录状态
   */
  async testCheckLogin() {
    const response = await this.request(API_PATHS.AUTH.CHECK)
    if (response.code !== 0) {
      throw new Error(`检查登录状态失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取简历列表
   */
  async testGetResumeList() {
    const response = await this.request(API_PATHS.PUBLIC.RESUME_LIST)
    if (response.code !== 0) {
      throw new Error(`获取简历列表失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取简历模板
   */
  async testGetResumeTemplates() {
    const response = await this.request(API_PATHS.RESUME.TEMPLATES)
    if (response.code !== 0) {
      throw new Error(`获取简历模板失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取积分余额
   */
  async testGetPointsBalance() {
    const response = await this.request(API_PATHS.POINTS.BALANCE)
    if (response.code !== 0) {
      throw new Error(`获取积分余额失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取积分规则
   */
  async testGetPointsRules() {
    const response = await this.request(API_PATHS.POINTS.RULES)
    if (response.code !== 0) {
      throw new Error(`获取积分规则失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取统计概览
   */
  async testGetStatisticsOverview() {
    const response = await this.request(API_PATHS.STATISTICS.OVERVIEW)
    if (response.code !== 0) {
      throw new Error(`获取统计概览失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 测试获取用户统计
   */
  async testGetUserStatistics() {
    const response = await this.request(API_PATHS.STATISTICS.USERS)
    if (response.code !== 0) {
      throw new Error(`获取用户统计失败: ${response.msg}`)
    }
    return response.data
  }

  /**
   * 打印测试总结
   */
  printTestSummary() {
    console.log('\n' + '=' * 50)
    console.log('📊 测试结果总结')
    console.log('=' * 50)
    
    const passed = this.testResults.filter(r => r.success).length
    const failed = this.testResults.filter(r => !r.success).length
    
    console.log(`✅ 通过: ${passed}`)
    console.log(`❌ 失败: ${failed}`)
    console.log(`📈 成功率: ${((passed / this.totalTests) * 100).toFixed(1)}%`)
    
    if (failed > 0) {
      console.log('\n❌ 失败的测试:')
      this.testResults
        .filter(r => !r.success)
        .forEach(r => {
          console.log(`  - ${r.name}: ${r.error}`)
        })
    }
    
    console.log('\n🎯 建议:')
    if (failed === 0) {
      console.log('  ✅ 所有接口测试通过，可以开始联调联试')
    } else if (failed <= 3) {
      console.log('  ⚠️  部分接口测试失败，建议检查后端服务状态')
    } else {
      console.log('  ❌ 多个接口测试失败，建议检查网络连接和后端服务')
    }
  }

  /**
   * 生成测试报告
   */
  generateReport() {
    const report = {
      timestamp: new Date().toISOString(),
      environment: this.config.BASE_URL,
      totalTests: this.totalTests,
      passed: this.testResults.filter(r => r.success).length,
      failed: this.testResults.filter(r => !r.success).length,
      results: this.testResults
    }
    
    return report
  }
}

/**
 * 运行测试
 */
function runAPITests() {
  const tester = new APITester()
  return tester.runAllTests()
}

/**
 * 导出测试类
 */
module.exports = {
  APITester,
  runAPITests
}
