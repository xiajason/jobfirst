/**
 * 向量数据库服务
 * 用于处理简历和职位的向量存储、索引和搜索
 */

import { ResumeContent, VectorSearchResult, VectorSearchOptions } from '@/types/ai-resume';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export interface VectorEmbedding {
  id: string;
  content_type: 'resume' | 'job' | 'company';
  content_id: string;
  embedding: number[];
  metadata: Record<string, any>;
  created_at: string;
  model_version: string;
  dimensions: number;
}

export interface VectorIndexInfo {
  index_name: string;
  vector_count: number;
  dimensions: number;
  metric: 'cosine' | 'euclidean' | 'dot_product';
  created_at: string;
  last_updated: string;
}

export class VectorDatabaseService {
  private static instance: VectorDatabaseService;
  private token: string | null = null;

  private constructor() {}

  public static getInstance(): VectorDatabaseService {
    if (!VectorDatabaseService.instance) {
      VectorDatabaseService.instance = new VectorDatabaseService();
    }
    return VectorDatabaseService.instance;
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
   * 创建简历向量嵌入
   */
  async createResumeEmbedding(
    resumeId: string, 
    content: ResumeContent,
    modelVersion: string = 'text-embedding-ada-002'
  ): Promise<VectorEmbedding> {
    const response = await fetch(`${API_URL}/api/v1/vector/resume/embed`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        resume_id: resumeId,
        content,
        model_version: modelVersion,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '创建简历向量嵌入失败');
    }

    return await response.json();
  }

  /**
   * 创建职位向量嵌入
   */
  async createJobEmbedding(
    jobId: string,
    jobData: {
      title: string;
      description: string;
      requirements: string[];
      company: string;
      industry: string;
      location: string;
    },
    modelVersion: string = 'text-embedding-ada-002'
  ): Promise<VectorEmbedding> {
    const response = await fetch(`${API_URL}/api/v1/vector/job/embed`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        job_id: jobId,
        job_data: jobData,
        model_version: modelVersion,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '创建职位向量嵌入失败');
    }

    return await response.json();
  }

  /**
   * 向量相似性搜索
   */
  async similaritySearch(
    queryEmbedding: number[],
    contentType: 'resume' | 'job' | 'company',
    options: VectorSearchOptions = {}
  ): Promise<VectorSearchResult[]> {
    const response = await fetch(`${API_URL}/api/v1/vector/search`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        query_embedding: queryEmbedding,
        content_type: contentType,
        ...options,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '向量搜索失败');
    }

    return await response.json();
  }

  /**
   * 简历与职位匹配搜索
   */
  async resumeJobMatch(
    resumeId: string,
    options: VectorSearchOptions = {}
  ): Promise<VectorSearchResult[]> {
    const response = await fetch(`${API_URL}/api/v1/vector/resume-job-match`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        resume_id: resumeId,
        ...options,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '简历职位匹配搜索失败');
    }

    return await response.json();
  }

  /**
   * 语义搜索
   */
  async semanticSearch(
    query: string,
    contentType: 'resume' | 'job' | 'company',
    options: VectorSearchOptions = {}
  ): Promise<VectorSearchResult[]> {
    const response = await fetch(`${API_URL}/api/v1/vector/semantic-search`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        query,
        content_type: contentType,
        ...options,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '语义搜索失败');
    }

    return await response.json();
  }

  /**
   * 获取向量索引信息
   */
  async getIndexInfo(): Promise<VectorIndexInfo[]> {
    const response = await fetch(`${API_URL}/api/v1/vector/indexes`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取向量索引信息失败');
    }

    return await response.json();
  }

  /**
   * 重建向量索引
   */
  async rebuildIndex(indexName: string): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`${API_URL}/api/v1/vector/indexes/${indexName}/rebuild`, {
      method: 'POST',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '重建向量索引失败');
    }

    return await response.json();
  }

  /**
   * 删除向量嵌入
   */
  async deleteEmbedding(embeddingId: string): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`${API_URL}/api/v1/vector/embeddings/${embeddingId}`, {
      method: 'DELETE',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '删除向量嵌入失败');
    }

    return await response.json();
  }

  /**
   * 批量更新向量嵌入
   */
  async batchUpdateEmbeddings(
    embeddings: Array<{
      id: string;
      content: any;
      metadata?: Record<string, any>;
    }>
  ): Promise<{ success: boolean; updated_count: number; errors: string[] }> {
    const response = await fetch(`${API_URL}/api/v1/vector/embeddings/batch-update`, {
      method: 'PUT',
      headers: this.getHeaders(),
      body: JSON.stringify({ embeddings }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '批量更新向量嵌入失败');
    }

    return await response.json();
  }

  /**
   * 获取向量统计信息
   */
  async getVectorStats(): Promise<{
    total_embeddings: number;
    total_resumes: number;
    total_jobs: number;
    total_companies: number;
    average_dimensions: number;
    storage_size_mb: number;
    last_updated: string;
  }> {
    const response = await fetch(`${API_URL}/api/v1/vector/stats`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取向量统计信息失败');
    }

    return await response.json();
  }

  /**
   * 向量聚类分析
   */
  async clusterAnalysis(
    contentType: 'resume' | 'job' | 'company',
    clusterCount: number = 5
  ): Promise<{
    clusters: Array<{
      cluster_id: number;
      centroid: number[];
      size: number;
      content_ids: string[];
      representative_keywords: string[];
    }>;
    silhouette_score: number;
    total_clusters: number;
  }> {
    const response = await fetch(`${API_URL}/api/v1/vector/cluster`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        content_type: contentType,
        cluster_count: clusterCount,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '向量聚类分析失败');
    }

    return await response.json();
  }
}

// 导出单例实例
export const vectorDbService = VectorDatabaseService.getInstance();

// 兼容性函数
export const createResumeEmbedding = (resumeId: string, content: ResumeContent, modelVersion?: string) => 
  vectorDbService.createResumeEmbedding(resumeId, content, modelVersion);

export const createJobEmbedding = (jobId: string, jobData: any, modelVersion?: string) => 
  vectorDbService.createJobEmbedding(jobId, jobData, modelVersion);

export const similaritySearch = (queryEmbedding: number[], contentType: 'resume' | 'job' | 'company', options?: VectorSearchOptions) => 
  vectorDbService.similaritySearch(queryEmbedding, contentType, options);

export const resumeJobMatch = (resumeId: string, options?: VectorSearchOptions) => 
  vectorDbService.resumeJobMatch(resumeId, options);

export const semanticSearch = (query: string, contentType: 'resume' | 'job' | 'company', options?: VectorSearchOptions) => 
  vectorDbService.semanticSearch(query, contentType, options);
