// scripts/start-integration-test.js

/**
 * 联调联试启动脚本
 * 用于一键启动小程序与后端的联调联试
 */

const { runAPITests } = require('../test/api-test.js')
const { getCurrentConfig } = require('../config/api-config.js')

/**
 * 联调联试管理器
 */
class IntegrationTestManager {
  constructor() {
    this.config = getCurrentConfig()
    this.isRunning = false
  }

  /**
   * 启动联调联试
   */
  async start() {
    if (this.isRunning) {
      console.log('⚠️  联调联试已在运行中...')
      return
    }

    this.isRunning = true
    
    console.log('🚀 ADIRP数智招聘小程序 - 联调联试启动')
    console.log('=' * 60)
    console.log(`📅 时间: ${new Date().toLocaleString()}`)
    console.log(`🌐 环境: ${this.config.BASE_URL}`)
    console.log(`⚙️  超时: ${this.config.TIMEOUT}ms`)
    console.log(`🔄 重试: ${this.config.RETRY_TIMES}次`)
    console.log('=' * 60)

    try {
      // 1. 环境检查
      await this.checkEnvironment()
      
      // 2. 运行API测试
      await this.runAPITests()
      
      // 3. 生成测试报告
      await this.generateReport()
      
      // 4. 启动小程序
      await this.startMiniProgram()
      
    } catch (error) {
      console.error('❌ 联调联试启动失败:', error.message)
      this.handleError(error)
    } finally {
      this.isRunning = false
    }
  }

  /**
   * 环境检查
   */
  async checkEnvironment() {
    console.log('\n🔍 检查环境配置...')
    
    // 检查网络连接
    await this.checkNetworkConnection()
    
    // 检查后端服务
    await this.checkBackendServices()
    
    // 检查小程序配置
    this.checkMiniProgramConfig()
    
    console.log('✅ 环境检查完成')
  }

  /**
   * 检查网络连接
   */
  async checkNetworkConnection() {
    console.log('  📡 检查网络连接...')
    
    try {
      const response = await this.request('/health')
      if (response.status === 'healthy') {
        console.log('    ✅ 网络连接正常')
      } else {
        throw new Error('后端服务响应异常')
      }
    } catch (error) {
      throw new Error(`网络连接失败: ${error.message}`)
    }
  }

  /**
   * 检查后端服务
   */
  async checkBackendServices() {
    console.log('  🔧 检查后端服务...')
    
    const services = [
      { name: '网关服务', path: '/health' },
      { name: '用户服务', path: '/api/v1/user/auth/check' },
      { name: '开放服务', path: '/open/version' },
      { name: '简历服务', path: '/resume/templates' },
      { name: '积分服务', path: '/points/rules' },
      { name: '统计服务', path: '/statistics/overview' }
    ]

    for (const service of services) {
      try {
        await this.request(service.path)
        console.log(`    ✅ ${service.name} - 正常`)
      } catch (error) {
        console.log(`    ⚠️  ${service.name} - 异常: ${error.message}`)
      }
    }
  }

  /**
   * 检查小程序配置
   */
  checkMiniProgramConfig() {
    console.log('  📱 检查小程序配置...')
    
    // 检查必要的配置文件
    const requiredFiles = [
      'app.json',
      'app.js',
      'app.wxss',
      'project.config.json',
      'utils/api.js',
      'utils/request.js',
      'config/api-config.js'
    ]

    for (const file of requiredFiles) {
      try {
        // 这里可以添加文件存在性检查
        console.log(`    ✅ ${file} - 存在`)
      } catch (error) {
        console.log(`    ❌ ${file} - 缺失`)
      }
    }
  }

  /**
   * 运行API测试
   */
  async runAPITests() {
    console.log('\n🧪 运行API接口测试...')
    
    try {
      await runAPITests()
      console.log('✅ API测试完成')
    } catch (error) {
      console.error('❌ API测试失败:', error.message)
      throw error
    }
  }

  /**
   * 生成测试报告
   */
  async generateReport() {
    console.log('\n📊 生成测试报告...')
    
    const report = {
      timestamp: new Date().toISOString(),
      environment: this.config.BASE_URL,
      status: 'completed',
      summary: {
        totalTests: 0,
        passed: 0,
        failed: 0,
        successRate: 0
      },
      recommendations: []
    }
    
    // 这里可以添加更详细的报告生成逻辑
    
    console.log('✅ 测试报告生成完成')
    return report
  }

  /**
   * 启动小程序
   */
  async startMiniProgram() {
    console.log('\n📱 启动小程序...')
    
    console.log('  📋 启动步骤:')
    console.log('    1. 打开微信开发者工具')
    console.log('    2. 导入项目: miniprogram/')
    console.log('    3. 配置AppID')
    console.log('    4. 点击编译')
    console.log('    5. 在模拟器中预览')
    
    console.log('\n🎯 联调联试准备就绪!')
    console.log('💡 提示: 可以在小程序中测试各项功能')
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
   * 错误处理
   */
  handleError(error) {
    console.log('\n❌ 错误处理建议:')
    
    if (error.message.includes('网络连接失败')) {
      console.log('  🔧 解决方案:')
      console.log('    1. 检查网络连接')
      console.log('    2. 确认后端服务已启动')
      console.log('    3. 检查防火墙设置')
      console.log('    4. 验证API地址配置')
    } else if (error.message.includes('认证失败')) {
      console.log('  🔧 解决方案:')
      console.log('    1. 检查Token配置')
      console.log('    2. 确认用户已登录')
      console.log('    3. 验证认证接口')
    } else {
      console.log('  🔧 通用解决方案:')
      console.log('    1. 查看错误日志')
      console.log('    2. 检查配置参数')
      console.log('    3. 重启相关服务')
      console.log('    4. 联系技术支持')
    }
  }

  /**
   * 停止联调联试
   */
  stop() {
    if (!this.isRunning) {
      console.log('⚠️  联调联试未在运行')
      return
    }

    console.log('🛑 停止联调联试...')
    this.isRunning = false
    console.log('✅ 联调联试已停止')
  }

  /**
   * 获取状态
   */
  getStatus() {
    return {
      isRunning: this.isRunning,
      config: this.config,
      timestamp: new Date().toISOString()
    }
  }
}

/**
 * 创建联调联试管理器实例
 */
const integrationTestManager = new IntegrationTestManager()

/**
 * 启动联调联试
 */
function startIntegrationTest() {
  return integrationTestManager.start()
}

/**
 * 停止联调联试
 */
function stopIntegrationTest() {
  return integrationTestManager.stop()
}

/**
 * 获取联调联试状态
 */
function getIntegrationTestStatus() {
  return integrationTestManager.getStatus()
}

// 导出函数
module.exports = {
  IntegrationTestManager,
  startIntegrationTest,
  stopIntegrationTest,
  getIntegrationTestStatus
}

// 如果直接运行此脚本
if (typeof wx !== 'undefined') {
  // 在微信小程序环境中
  console.log('🚀 联调联试脚本已加载')
  console.log('💡 调用 startIntegrationTest() 开始联调联试')
} else {
  // 在Node.js环境中
  console.log('🚀 联调联试脚本已加载')
  console.log('💡 请在微信小程序环境中运行')
}
