/**
 * PostgreSQL数据库服务
 * 用于存储简历、职位、用户数据和向量元数据
 */

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export interface DatabaseConnection {
  host: string;
  port: number;
  database: string;
  user: string;
  ssl: boolean;
  status: 'connected' | 'disconnected' | 'error';
  last_check: string;
}

export interface DatabaseStats {
  total_tables: number;
  total_records: number;
  database_size_mb: number;
  connection_pool_size: number;
  active_connections: number;
  slow_queries_count: number;
  last_backup: string;
}

export interface TableInfo {
  table_name: string;
  record_count: number;
  size_mb: number;
  last_updated: string;
  indexes: string[];
}

export class PostgreSQLService {
  private static instance: PostgreSQLService;
  private token: string | null = null;

  private constructor() {}

  public static getInstance(): PostgreSQLService {
    if (!PostgreSQLService.instance) {
      PostgreSQLService.instance = new PostgreSQLService();
    }
    return PostgreSQLService.instance;
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
   * 获取数据库连接状态
   */
  async getConnectionStatus(): Promise<DatabaseConnection> {
    const response = await fetch(`${API_URL}/api/v1/database/status`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取数据库状态失败');
    }

    return await response.json();
  }

  /**
   * 获取数据库统计信息
   */
  async getDatabaseStats(): Promise<DatabaseStats> {
    const response = await fetch(`${API_URL}/api/v1/database/stats`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取数据库统计信息失败');
    }

    return await response.json();
  }

  /**
   * 获取表信息
   */
  async getTableInfo(): Promise<TableInfo[]> {
    const response = await fetch(`${API_URL}/api/v1/database/tables`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取表信息失败');
    }

    return await response.json();
  }

  /**
   * 执行SQL查询
   */
  async executeQuery(sql: string, params?: any[]): Promise<any[]> {
    const response = await fetch(`${API_URL}/api/v1/database/query`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        sql,
        params: params || [],
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '执行SQL查询失败');
    }

    return await response.json();
  }

  /**
   * 备份数据库
   */
  async backupDatabase(backupName?: string): Promise<{ success: boolean; backup_file: string; size_mb: number }> {
    const response = await fetch(`${API_URL}/api/v1/database/backup`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        backup_name: backupName || `backup_${new Date().toISOString().split('T')[0]}`,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '数据库备份失败');
    }

    return await response.json();
  }

  /**
   * 恢复数据库
   */
  async restoreDatabase(backupFile: string): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`${API_URL}/api/v1/database/restore`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        backup_file: backupFile,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '数据库恢复失败');
    }

    return await response.json();
  }

  /**
   * 优化数据库
   */
  async optimizeDatabase(): Promise<{ success: boolean; message: string; optimized_tables: string[] }> {
    const response = await fetch(`${API_URL}/api/v1/database/optimize`, {
      method: 'POST',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '数据库优化失败');
    }

    return await response.json();
  }

  /**
   * 获取慢查询日志
   */
  async getSlowQueries(limit: number = 100): Promise<Array<{
    query: string;
    execution_time_ms: number;
    timestamp: string;
    table_name: string;
  }>> {
    const response = await fetch(`${API_URL}/api/v1/database/slow-queries?limit=${limit}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取慢查询日志失败');
    }

    return await response.json();
  }

  /**
   * 创建数据库索引
   */
  async createIndex(
    tableName: string,
    columnName: string,
    indexType: 'btree' | 'hash' | 'gin' | 'gist' = 'btree'
  ): Promise<{ success: boolean; index_name: string; message: string }> {
    const response = await fetch(`${API_URL}/api/v1/database/indexes`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({
        table_name: tableName,
        column_name: columnName,
        index_type: indexType,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '创建数据库索引失败');
    }

    return await response.json();
  }

  /**
   * 删除数据库索引
   */
  async dropIndex(indexName: string): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`${API_URL}/api/v1/database/indexes/${indexName}`, {
      method: 'DELETE',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '删除数据库索引失败');
    }

    return await response.json();
  }

  /**
   * 获取数据库锁信息
   */
  async getLocks(): Promise<Array<{
    lock_type: string;
    table_name: string;
    process_id: number;
    query: string;
    duration_ms: number;
  }>> {
    const response = await fetch(`${API_URL}/api/v1/database/locks`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取数据库锁信息失败');
    }

    return await response.json();
  }

  /**
   * 终止数据库连接
   */
  async terminateConnection(processId: number): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`${API_URL}/api/v1/database/connections/${processId}`, {
      method: 'DELETE',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '终止数据库连接失败');
    }

    return await response.json();
  }

  /**
   * 获取数据库性能指标
   */
  async getPerformanceMetrics(): Promise<{
    queries_per_second: number;
    average_response_time_ms: number;
    cache_hit_ratio: number;
    active_connections: number;
    max_connections: number;
    connection_utilization: number;
  }> {
    const response = await fetch(`${API_URL}/api/v1/database/performance`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '获取数据库性能指标失败');
    }

    return await response.json();
  }

  /**
   * 清理过期数据
   */
  async cleanupExpiredData(options: {
    table_name: string;
    date_column: string;
    retention_days: number;
  }): Promise<{ success: boolean; deleted_count: number; message: string }> {
    const response = await fetch(`${API_URL}/api/v1/database/cleanup`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(options),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || '清理过期数据失败');
    }

    return await response.json();
  }
}

// 导出单例实例
export const postgresqlService = PostgreSQLService.getInstance();

// 兼容性函数
export const getConnectionStatus = () => postgresqlService.getConnectionStatus();
export const getDatabaseStats = () => postgresqlService.getDatabaseStats();
export const getTableInfo = () => postgresqlService.getTableInfo();
export const executeQuery = (sql: string, params?: any[]) => postgresqlService.executeQuery(sql, params);
export const backupDatabase = (backupName?: string) => postgresqlService.backupDatabase(backupName);
export const restoreDatabase = (backupFile: string) => postgresqlService.restoreDatabase(backupFile);
export const optimizeDatabase = () => postgresqlService.optimizeDatabase();
export const getSlowQueries = (limit?: number) => postgresqlService.getSlowQueries(limit);
export const createIndex = (tableName: string, columnName: string, indexType?: 'btree' | 'hash' | 'gin' | 'gist') => 
  postgresqlService.createIndex(tableName, columnName, indexType);
export const dropIndex = (indexName: string) => postgresqlService.dropIndex(indexName);
export const getLocks = () => postgresqlService.getLocks();
export const terminateConnection = (processId: number) => postgresqlService.terminateConnection(processId);
export const getPerformanceMetrics = () => postgresqlService.getPerformanceMetrics();
export const cleanupExpiredData = (options: any) => postgresqlService.cleanupExpiredData(options);
