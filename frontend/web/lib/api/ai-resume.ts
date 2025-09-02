import { ResumeAnalysisResult, ResumeOptimizationResult, VectorSearchResult } from '@/types/ai-resume';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

/**
 * AI简历分析服务API
 */
export class AIResumeService {
  private static instance: AIResumeService;
  private token: string | null = null;

  private constructor() {}

  public static getInstance(): AIResumeService {
    if (!AIResumeService.instance) {
      AIResumeService.instance = new AIResumeService();
    }
    return AIResumeService.instance;
  }

  public setToken(token: string) {
    this.token = token;
  }

  public clearToken() {
    this.token = null;
  }

  private getHeaders(): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };
    
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    
    return headers;
  }

  /**
   * 上传简历文件
   */
  async uploadResumeFile(file: File): Promise<{ resume_id: string; filename: string; size: number }> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_type', 'resume');

    const response = await fetch(`${API_URL}/api/v1/ai/resume/upload`, {
      method: 'POST',
      headers: {
        'Authorization': this.token ? `Bearer ${this.token}` : '',
      },
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '简历上传失败');
    }

    return await response.json();
  }

  /**
   * 上传简历文本
   */
  async uploadResumeText(content: string): Promise<{ resume_id: string; content_length: number }> {
    const response = await fetch(`${API_URL}/api/v1/ai/resume/upload-text`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({ content }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '简历文本上传失败');
    }

    return await response.json();
  }

  /**
   * AI简历分析
   */
  async analyzeResume(resumeId: string, options?: {
    targetJob?: string;
    industry?: string;
    experience?: string;
    analysisType?: 'basic' | 'comprehensive' | 'expert';
  }): Promise<ResumeAnalysisResult> {
    const response = await fetch(`${API_URL}/api/v1/ai/resume/analyze`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        resume_id: resumeId,
        ...options,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '简历分析失败');
    }

    return await response.json();
  }

  /**
   * AI简历优化
   */
  async optimizeResume(resumeId: string, analysisId: string, options?: {
    optimizationFocus?: 'skills' | 'experience' | 'format' | 'all';
    targetJob?: string;
    industry?: string;
  }): Promise<ResumeOptimizationResult> {
    const response = await fetch(`${API_URL}/api/v1/ai/resume/optimize`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        resume_id: resumeId,
        analysis_id: analysisId,
        ...options,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '简历优化失败');
    }

    return await response.json();
  }

  /**
   * 向量搜索相似职位
   */
  async searchSimilarJobs(resumeId: string, limit: number = 10): Promise<VectorSearchResult[]> {
    const response = await fetch(`${API_URL}/api/v1/ai/resume/similar-jobs`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        resume_id: resumeId,
        limit,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '相似职位搜索失败');
    }

    return await response.json();
  }

  /**
   * 获取简历分析历史
   */
  async getAnalysisHistory(resumeId: string): Promise<ResumeAnalysisResult[]> {
    const response = await fetch(`${API_URL}/api/v1/ai/resume/history/${resumeId}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取分析历史失败');
    }

    return await response.json();
  }

  /**
   * 导出优化后的简历
   */
  async exportResume(resumeId: string, format: 'pdf' | 'docx' | 'txt' = 'pdf'): Promise<Blob> {
    const response = await fetch(`${API_URL}/api/v1/ai/resume/export`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        resume_id: resumeId,
        format,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '简历导出失败');
    }

    return await response.blob();
  }

  /**
   * 获取AI分析统计信息
   */
  async getAnalysisStats(resumeId: string): Promise<{
    total_analyses: number;
    average_score: number;
    improvement_trend: number;
    last_analysis_date: string;
  }> {
    const response = await fetch(`${API_URL}/api/v1/ai/resume/stats/${resumeId}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取统计信息失败');
    }

    return await response.json();
  }
}

// 导出单例实例
export const aiResumeService = AIResumeService.getInstance();

// 兼容性函数
export const uploadResumeFile = (file: File) => aiResumeService.uploadResumeFile(file);
export const uploadResumeText = (content: string) => aiResumeService.uploadResumeText(content);
export const analyzeResume = (resumeId: string, options?: any) => aiResumeService.analyzeResume(resumeId, options);
export const optimizeResume = (resumeId: string, analysisId: string, options?: any) => aiResumeService.optimizeResume(resumeId, analysisId, options);
export const searchSimilarJobs = (resumeId: string, limit?: number) => aiResumeService.searchSimilarJobs(resumeId, limit);
export const getAnalysisHistory = (resumeId: string) => aiResumeService.getAnalysisHistory(resumeId);
export const exportResume = (resumeId: string, format?: 'pdf' | 'docx' | 'txt') => aiResumeService.exportResume(resumeId, format);
export const getAnalysisStats = (resumeId: string) => aiResumeService.getAnalysisStats(resumeId);
