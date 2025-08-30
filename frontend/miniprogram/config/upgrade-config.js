// 数据库升级配置管理
const UPGRADE_CONFIG = {
  // 当前API版本
  CURRENT_API_VERSION: 'v2',  // 升级到v2
  
  // 新功能开关
  FEATURE_FLAGS: {
    USE_NEW_DATABASE: true,      // 启用新数据库
    USE_NEW_API: true,           // 启用新API
    ENABLE_CHAT: true,           // ✅ 启用聊天功能
    ENABLE_POINTS: true,         // ✅ 启用积分系统
    ENABLE_NOTIFICATIONS: true,  // ✅ 启用通知系统
  },
  
  // API版本配置
  API_VERSIONS: {
    v1: {
      name: 'v1',
      description: '旧版本API',
      baseUrl: 'http://localhost:8080',
      features: ['basic_auth', 'job_search', 'resume_basic'],
      deprecated: false
    },
    v2: {
      name: 'v2',
      description: '新版本API',
      baseUrl: 'http://localhost:8080',  // 强制锁定为正确地址
      features: ['oauth2', 'job_search', 'resume_advanced', 'chat', 'points', 'notifications'],
      deprecated: false
    }
  },
  
  // 数据迁移配置
  MIGRATION_CONFIG: {
    // 是否启用数据适配
    enableDataAdapter: true,
    
    // 适配器配置
    adapters: {
      user: {
        enabled: true,
        fields: ['openid', 'unionid', 'user_type', 'certification_status']
      },
      job: {
        enabled: true,
        fields: ['category_id', 'skills', 'tags', 'priority']
      },
      company: {
        enabled: true,
        fields: ['verification_level', 'job_count', 'view_count']
      },
      banner: {
        enabled: true,
        fields: ['link_type', 'start_time', 'end_time']
      },
      chat: {
        enabled: true,
        fields: ['message_type', 'read_status', 'attachment_url']
      }
    }
  },
  
  // 降级策略 (已禁用)
  FALLBACK_STRATEGY: {
    // 新API失败时是否降级到旧API
    enableFallback: false,
    
    // 降级条件
    fallbackConditions: {
      timeout: 5000,        // 超时时间(ms)
      maxRetries: 3,        // 最大重试次数
      errorCodes: [500, 502, 503, 504]  // 触发降级的错误码
    }
  }
}

// 升级管理器
class UpgradeManager {
  constructor() {
    this.config = UPGRADE_CONFIG
    this.currentVersion = this.config.CURRENT_API_VERSION
    this.featureFlags = this.config.FEATURE_FLAGS
  }
  
  // 获取当前API版本
  getCurrentAPIVersion() {
    return this.currentVersion
  }
  
  // 设置API版本
  setAPIVersion(version) {
    if (this.config.API_VERSIONS[version]) {
      this.currentVersion = version
      this.saveConfig()
      return true
    }
    return false
  }
  
  // 检查功能是否启用
  isFeatureEnabled(feature) {
    return this.featureFlags[feature] || false
  }
  
  // 启用功能
  enableFeature(feature) {
    if (this.featureFlags.hasOwnProperty(feature)) {
      this.featureFlags[feature] = true
      this.saveConfig()
      return true
    }
    return false
  }
  
  // 禁用功能
  disableFeature(feature) {
    if (this.featureFlags.hasOwnProperty(feature)) {
      this.featureFlags[feature] = false
      this.saveConfig()
      return true
    }
    return false
  }
  
  // 获取API配置
  getAPIConfig(version = null) {
    const targetVersion = version || this.currentVersion
    return this.config.API_VERSIONS[targetVersion] || this.config.API_VERSIONS.v1
  }
  
  // 检查是否需要数据适配
  needsDataAdapter(dataType) {
    if (!this.config.MIGRATION_CONFIG.enableDataAdapter) {
      return false
    }
    
    const adapter = this.config.MIGRATION_CONFIG.adapters[dataType]
    return adapter && adapter.enabled
  }
  
  // 获取适配字段
  getAdapterFields(dataType) {
    const adapter = this.config.MIGRATION_CONFIG.adapters[dataType]
    return adapter ? adapter.fields : []
  }
  
  // 检查是否需要降级
  shouldFallback(errorCode, retryCount) {
    if (!this.config.FALLBACK_STRATEGY.enableFallback) {
      return false
    }
    
    const conditions = this.config.FALLBACK_STRATEGY.fallbackConditions
    
    // 检查错误码
    if (conditions.errorCodes.includes(errorCode)) {
      return true
    }
    
    // 检查重试次数
    if (retryCount >= conditions.maxRetries) {
      return true
    }
    
    return false
  }
  
  // 执行降级 (已禁用)
  performFallback() {
    console.log('API降级功能已禁用')
    return false
  }
  
  // 保存配置到本地存储
  saveConfig() {
    try {
      wx.setStorageSync('upgrade_config', {
        currentVersion: this.currentVersion,
        featureFlags: this.featureFlags
      })
    } catch (error) {
      console.error('Failed to save upgrade config:', error)
    }
  }
  
  // 从本地存储加载配置
  loadConfig() {
    try {
      const savedConfig = wx.getStorageSync('upgrade_config')
      if (savedConfig) {
        this.currentVersion = savedConfig.currentVersion || this.currentVersion
        this.featureFlags = { ...this.featureFlags, ...savedConfig.featureFlags }
      }
    } catch (error) {
      console.error('Failed to load upgrade config:', error)
    }
  }
  
  // 获取升级状态
  getUpgradeStatus() {
    return {
      currentVersion: this.currentVersion,
      featureFlags: this.featureFlags,
      isUsingNewAPI: this.currentVersion === 'v2',
      isUsingNewDatabase: this.featureFlags.USE_NEW_DATABASE,
      availableFeatures: this.getAPIConfig().features
    }
  }
  
  // 执行渐进式升级
  performGradualUpgrade() {
    const steps = [
      {
        name: '启用新数据库',
        action: () => this.enableFeature('USE_NEW_DATABASE'),
        description: '启用新数据库表结构'
      },
      {
        name: '启用新API',
        action: () => this.setAPIVersion('v2'),
        description: '切换到新API版本'
      },
      {
        name: '启用聊天功能',
        action: () => this.enableFeature('ENABLE_CHAT'),
        description: '启用聊天系统'
      },
      {
        name: '启用积分系统',
        action: () => this.enableFeature('ENABLE_POINTS'),
        description: '启用积分功能'
      },
      {
        name: '启用通知系统',
        action: () => this.enableFeature('ENABLE_NOTIFICATIONS'),
        description: '启用通知功能'
      }
    ]
    
    return steps
  }
}

// 创建全局升级管理器实例
const upgradeManager = new UpgradeManager()

// 初始化时加载配置
upgradeManager.loadConfig()

// 导出配置和管理器
module.exports = {
  UPGRADE_CONFIG,
  UpgradeManager,
  upgradeManager
}
