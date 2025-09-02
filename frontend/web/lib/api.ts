// API客户端 - 支持多模式权限控制
import { hasApiAccess, getCurrentMode } from '@/config/modes';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api.adirp.com';

export interface ApiResponse<T = any> {
  success: boolean;
  code: number;
  message: string;
  data: T;
  timestamp: number;
}

export interface ApiError {
  success: false;
  code: number;
  message: string;
  error: string;
  timestamp: number;
}

class ApiClient {
  private baseUrl: string;
  private token: string | null = null;

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  // 设置认证token
  setToken(token: string) {
    this.token = token;
  }

  // 清除token
  clearToken() {
    this.token = null;
  }

  // 检查API权限
  private checkApiPermission(endpoint: string): boolean {
    if (!hasApiAccess(endpoint)) {
      const currentMode = getCurrentMode();
      throw new Error(`当前模式 (${currentMode.name}) 不支持此API: ${endpoint}`);
    }
    return true;
  }

  // 构建请求头
  private getHeaders(): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    return headers;
  }

  // 通用请求方法
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    // 检查API权限
    this.checkApiPermission(endpoint);

    const url = `${this.baseUrl}${endpoint}`;
    const config: RequestInit = {
      ...options,
      headers: {
        ...this.getHeaders(),
        ...options.headers,
      },
    };

    try {
      const response = await fetch(url, config);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || `HTTP ${response.status}`);
      }

      return data;
    } catch (error) {
      console.error('API请求失败:', error);
      throw error;
    }
  }

  // GET请求
  async get<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  // POST请求
  async post<T>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  // PUT请求
  async put<T>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  // DELETE请求
  async delete<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }

  // 文件上传
  async upload<T>(endpoint: string, file: File): Promise<ApiResponse<T>> {
    this.checkApiPermission(endpoint);

    const formData = new FormData();
    formData.append('file', file);

    const url = `${this.baseUrl}${endpoint}`;
    const config: RequestInit = {
      method: 'POST',
      headers: {
        'Authorization': this.token ? `Bearer ${this.token}` : '',
      },
      body: formData,
    };

    try {
      const response = await fetch(url, config);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || `HTTP ${response.status}`);
      }

      return data;
    } catch (error) {
      console.error('文件上传失败:', error);
      throw error;
    }
  }
}

// 创建API客户端实例
export const apiClient = new ApiClient();

// 认证相关API
export const authApi = {
  // 用户登录
  login: (phone: string, password: string) =>
    apiClient.post('/api/auth/login', { phone, password }),

  // 用户注册
  register: (data: {
    phone: string;
    code: string;
    password: string;
    userType: string;
  }) => apiClient.post('/api/auth/register', data),

  // 发送验证码
  sendCode: (phone: string, type: string) =>
    apiClient.post('/api/auth/send-code', { phone, type }),
};

// 用户相关API
export const userApi = {
  // 获取用户信息
  getProfile: () => apiClient.get('/api/v1/user/profile'),

  // 更新用户信息
  updateProfile: (data: any) =>
    apiClient.put('/api/v1/user/profile', data),

  // 修改密码
  changePassword: (oldPassword: string, newPassword: string) =>
    apiClient.put('/api/v1/user/password', { oldPassword, newPassword }),
};

// 简历相关API
export const resumeApi = {
  // 获取简历列表
  getList: () => apiClient.get('/api/v1/resume/list'),

  // 创建简历
  create: (data: any) => apiClient.post('/api/v1/resume/create', data),

  // 更新简历
  update: (resumeId: string, data: any) =>
    apiClient.put(`/api/v1/resume/${resumeId}`, data),

  // 删除简历
  delete: (resumeId: string) =>
    apiClient.delete(`/api/v1/resume/${resumeId}`),

  // 上传简历文件
  upload: (file: File) => apiClient.upload('/api/v1/resume/upload', file),
};

// 职位相关API
export const jobsApi = {
  // 获取职位列表
  getList: (params?: any) => {
    const queryString = params ? `?${new URLSearchParams(params)}` : '';
    return apiClient.get(`/api/jobs${queryString}`);
  },

  // 获取职位详情
  getDetail: (jobId: string) => apiClient.get(`/api/jobs/${jobId}`),

  // 搜索职位
  search: (params: any) => {
    const queryString = new URLSearchParams(params);
    return apiClient.get(`/api/jobs/search?${queryString}`);
  },
};

// AI相关API (仅增强版和专业版)
export const aiApi = {
  // AI聊天
  chat: (message: string, context?: string) =>
    apiClient.post('/api/v1/ai/chat', { message, context }),

  // 简历分析
  analyzeResume: (resumeId: string, targetJob: string) =>
    apiClient.post('/api/v1/ai/resume-analysis', { resumeId, targetJob }),

  // 职位推荐
  recommendJobs: (resumeId: string, preferences: any) =>
    apiClient.post('/api/v1/ai/job-recommendation', { resumeId, preferences }),

  // AI简历优化
  optimizeResume: (resumeData: {
    content: string;
    targetJob?: string;
    industry?: string;
    experience?: string;
  }) => apiClient.post('/api/v1/ai/resume/optimize', resumeData),

  // 获取简历分析报告
  getResumeAnalysis: (resumeId: string) => 
    apiClient.get(`/api/v1/ai/resume/analysis/${resumeId}`),

  // 高级AI分析（专业版功能）
  advancedAnalysis: (data: {
    resumeContent: string;
    jobRequirements: string;
    industryData: any;
    competitorAnalysis: boolean;
  }) => apiClient.post('/api/v1/ai/advanced-analysis', data),
};

// 积分相关API (仅增强版和专业版)
export const pointsApi = {
  // 获取积分余额
  getBalance: () => apiClient.get('/api/v1/points/balance'),

  // 获取积分历史
  getHistory: (params?: any) => {
    const queryString = params ? `?${new URLSearchParams(params)}` : '';
    return apiClient.get(`/api/v1/points/history${queryString}`);
  },

  // 积分兑换
  exchange: (productId: string, points: number) =>
    apiClient.post('/api/v1/points/exchange', { productId, points }),
};

// 统计相关API (仅增强版和专业版)
export const statisticsApi = {
  // 获取市场数据
  getMarketData: () => apiClient.get('/api/v1/statistics/market'),

  // 获取个人数据
  getPersonalData: () => apiClient.get('/api/v1/statistics/personal'),

  // 获取企业数据
  getEnterpriseData: () => apiClient.get('/api/v1/statistics/enterprise'),
};

// 文件存储API
export const storageApi = {
  // 上传文件
  upload: (file: File) => apiClient.upload('/api/v1/storage/upload', file),

  // 获取文件信息
  getFileInfo: (fileId: string) =>
    apiClient.get(`/api/v1/storage/file/${fileId}`),

  // 删除文件
  deleteFile: (fileId: string) =>
    apiClient.delete(`/api/v1/storage/file/${fileId}`),
};

// 管理API (仅专业版)
export const adminApi = {
  // 获取系统状态
  getSystemStatus: () => apiClient.get('/admin/system/status'),

  // 获取服务健康状态
  getHealthStatus: () => apiClient.get('/admin/system/health'),

  // 获取系统指标
  getMetrics: () => apiClient.get('/admin/system/metrics'),
};

export default apiClient;
