/**
 * AI简历分析相关类型定义
 */

// 简历基本信息
export interface ResumeBasicInfo {
  resume_id: string;
  filename?: string;
  content_length: number;
  upload_time: string;
  file_type?: 'pdf' | 'docx' | 'txt' | 'manual';
  file_size?: number;
}

// 简历内容结构
export interface ResumeContent {
  personal_info: {
    name: string;
    title?: string;
    email?: string;
    phone?: string;
    location?: string;
    website?: string;
    linkedin?: string;
    github?: string;
  };
  summary?: string;
  experience: Array<{
    id: number;
    title: string;
    company: string;
    location?: string;
    years?: string;
    description: string[];
  }>;
  education: Array<{
    id: number;
    institution: string;
    degree: string;
    years?: string;
    description?: string;
  }>;
  skills: string[];
  projects?: Array<{
    id: number;
    name: string;
    description: string;
    technologies: string[];
    link?: string;
  }>;
  certifications?: Array<{
    id: number;
    name: string;
    issuer: string;
    date: string;
    link?: string;
  }>;
}

// AI分析结果
export interface ResumeAnalysisResult {
  analysis_id: string;
  resume_id: string;
  analysis_time: string;
  analysis_type: 'basic' | 'comprehensive' | 'expert';
  
  // 基础评分
  overall_score: number;
  content_score: number;
  format_score: number;
  relevance_score: number;
  
  // 详细分析
  strengths: string[];
  weaknesses: string[];
  suggestions: Array<{
    category: 'skills' | 'experience' | 'format' | 'content' | 'general';
    suggestion: string;
    priority: 'low' | 'medium' | 'high';
    impact: string;
    line_reference?: string;
  }>;
  
  // 技能分析
  skill_analysis: {
    technical_skills: Array<{
      skill: string;
      level: 'beginner' | 'intermediate' | 'advanced' | 'expert';
      relevance: number;
      market_demand: number;
    }>;
    soft_skills: Array<{
      skill: string;
      evidence: string;
      strength: number;
    }>;
    missing_skills: Array<{
      skill: string;
      importance: number;
      learning_path?: string;
    }>;
  };
  
  // 经验分析
  experience_analysis: {
    years_experience: number;
    industry_relevance: number;
    leadership_experience: boolean;
    project_scale: 'small' | 'medium' | 'large' | 'enterprise';
    quantifiable_achievements: number;
  };
  
  // 市场分析
  market_analysis: {
    industry_match: string;
    job_level_match: string;
    salary_range: {
      min: number;
      max: number;
      currency: string;
      location: string;
    };
    market_demand: 'low' | 'medium' | 'high' | 'very_high';
    competitor_position: 'below_average' | 'average' | 'above_average' | 'top';
  };
  
  // 向量嵌入信息
  vector_embedding?: {
    embedding_id: string;
    model_version: string;
    dimensions: number;
    similarity_threshold: number;
  };
}

// 简历优化结果
export interface ResumeOptimizationResult {
  optimization_id: string;
  resume_id: string;
  analysis_id: string;
  optimization_time: string;
  
  // 优化后的内容
  optimized_content: ResumeContent;
  
  // 优化详情
  optimizations: Array<{
    category: 'skills' | 'experience' | 'format' | 'content' | 'keywords';
    original: string;
    optimized: string;
    reason: string;
    impact_score: number;
  }>;
  
  // 关键词优化
  keyword_optimization: {
    added_keywords: string[];
    removed_keywords: string[];
    keyword_density: Record<string, number>;
    seo_score: number;
  };
  
  // 格式优化
  format_optimization: {
    structure_improvements: string[];
    readability_score: number;
    ats_compatibility: boolean;
    visual_enhancements: string[];
  };
  
  // 优化效果
  improvement_metrics: {
    overall_score_change: number;
    content_score_change: number;
    format_score_change: number;
    relevance_score_change: number;
    keyword_match_improvement: number;
  };
}

// 向量搜索结果
export interface VectorSearchResult {
  job_id: string;
  title: string;
  company: string;
  location: string;
  similarity_score: number;
  
  // 匹配详情
  match_details: {
    skill_match: number;
    experience_match: number;
    industry_match: number;
    location_match: number;
    salary_match: number;
  };
  
  // 职位信息
  job_info: {
    description: string;
    requirements: string[];
    responsibilities: string[];
    salary_range?: {
      min: number;
      max: number;
      currency: string;
    };
    job_type: 'full-time' | 'part-time' | 'contract' | 'internship';
    remote_option: boolean;
    experience_level: 'entry' | 'mid' | 'senior' | 'lead' | 'executive';
  };
  
  // 公司信息
  company_info: {
    name: string;
    industry: string;
    size: 'startup' | 'small' | 'medium' | 'large' | 'enterprise';
    location: string;
    website?: string;
    description?: string;
  };
  
  // 向量信息
  vector_info: {
    embedding_id: string;
    model_version: string;
    dimensions: number;
    distance_metric: string;
  };
}

// AI分析请求选项
export interface AIAnalysisOptions {
  targetJob?: string;
  industry?: string;
  experience?: string;
  analysisType?: 'basic' | 'comprehensive' | 'expert';
  includeVectorEmbedding?: boolean;
  includeMarketAnalysis?: boolean;
  includeCompetitorAnalysis?: boolean;
}

// AI优化请求选项
export interface AIOptimizationOptions {
  optimizationFocus?: 'skills' | 'experience' | 'format' | 'content' | 'keywords' | 'all';
  targetJob?: string;
  industry?: string;
  includeKeywordOptimization?: boolean;
  includeFormatOptimization?: boolean;
  includeContentEnhancement?: boolean;
  maintainOriginalStyle?: boolean;
}

// 向量搜索选项
export interface VectorSearchOptions {
  limit?: number;
  similarityThreshold?: number;
  includeJobDetails?: boolean;
  includeCompanyInfo?: boolean;
  filterByLocation?: string;
  filterByIndustry?: string;
  filterBySalaryRange?: {
    min: number;
    max: number;
    currency: string;
  };
}

// API响应包装器
export interface APIResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  error?: string;
  timestamp: string;
  request_id: string;
}

// 分页响应
export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    page_size: number;
    total: number;
    total_pages: number;
    has_next: boolean;
    has_prev: boolean;
  };
}

// 错误响应
export interface ErrorResponse {
  success: false;
  error: string;
  error_code: string;
  message: string;
  timestamp: string;
  request_id: string;
  details?: Record<string, any>;
}

// 导出类型
export type {
  ResumeBasicInfo,
  ResumeContent,
  ResumeAnalysisResult,
  ResumeOptimizationResult,
  VectorSearchResult,
  AIAnalysisOptions,
  AIOptimizationOptions,
  VectorSearchOptions,
  APIResponse,
  PaginatedResponse,
  ErrorResponse,
};
