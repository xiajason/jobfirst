// 多模式配置文件
export type Mode = 'basic' | 'plus' | 'pro';

export interface ModeConfig {
  name: string;
  description: string;
  features: string[];
  apiEndpoints: string[];
  maxUsers?: number;
  price?: number;
}

export const MODES: Record<Mode, ModeConfig> = {
  basic: {
    name: '基础版',
    description: '核心功能，轻量级部署',
    features: [
      '用户注册登录',
      '基础简历管理',
      '职位搜索',
      '基础聊天功能',
      '文件上传(10MB)',
      '基础数据统计'
    ],
    apiEndpoints: [
      '/api/auth/*',
      '/api/v1/user/*',
      '/api/v1/resume/*',
      '/api/jobs/*',
      '/api/companies/*'
    ],
    maxUsers: 1000,
    price: 0
  },
  plus: {
    name: '增强版',
    description: '增加数据分析能力',
    features: [
      '基础版所有功能',
      '高级数据分析',
      'ai_resume_optimization',
      'smart_job_recommendation',
      '积分系统',
      '高级聊天功能',
      '文件上传(50MB)',
      '详细数据统计',
      '个性化推荐'
    ],
    apiEndpoints: [
      '/api/auth/*',
      '/api/v1/user/*',
      '/api/v1/resume/*',
      '/api/v1/ai/*',
      '/api/v1/points/*',
      '/api/v1/statistics/*',
      '/api/v1/personal/*',
      '/api/jobs/*',
      '/api/companies/*'
    ],
    maxUsers: 10000,
    price: 99
  },
  pro: {
    name: '专业版',
    description: '全功能企业级方案',
    features: [
      '增强版所有功能',
      '企业级管理',
      '团队协作',
      'advanced_ai_analysis',
      'custom_workflow',
      'API集成',
      '高级安全功能',
      '无限文件上传',
      '实时数据分析',
      '企业级支持',
      '自定义品牌',
      '多语言支持'
    ],
    apiEndpoints: [
      '/api/auth/*',
      '/api/v1/*',
      '/api/v2/*',
      '/admin/*',
      '/api/jobs/*',
      '/api/companies/*'
    ],
    maxUsers: 100000,
    price: 299
  }
};

// 当前模式 (可通过环境变量设置)
export const CURRENT_MODE: Mode = (process.env.NEXT_PUBLIC_MODE as Mode) || 'basic';

// 模式特性检查函数
export const hasFeature = (feature: string): boolean => {
  const mode = MODES[CURRENT_MODE];
  return mode.features.includes(feature);
};

// 模式权限检查函数
export const hasApiAccess = (endpoint: string): boolean => {
  const mode = MODES[CURRENT_MODE];
  return mode.apiEndpoints.some(pattern => {
    if (pattern.endsWith('/*')) {
      return endpoint.startsWith(pattern.slice(0, -2));
    }
    return endpoint === pattern;
  });
};

// 获取当前模式配置
export const getCurrentMode = (): ModeConfig => {
  return MODES[CURRENT_MODE];
};

// 模式升级检查
export const canUpgrade = (currentMode: Mode): Mode[] => {
  const modeOrder: Mode[] = ['basic', 'plus', 'pro'];
  const currentIndex = modeOrder.indexOf(currentMode);
  return modeOrder.slice(currentIndex + 1);
};

// 模式降级检查
export const canDowngrade = (currentMode: Mode): Mode[] => {
  const modeOrder: Mode[] = ['basic', 'plus', 'pro'];
  const currentIndex = modeOrder.indexOf(currentMode);
  return modeOrder.slice(0, currentIndex);
};
