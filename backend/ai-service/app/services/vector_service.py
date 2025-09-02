"""
JobFirst 向量服务
处理向量数据库操作、相似性搜索等功能
"""

import asyncio
import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
import numpy as np
from dataclasses import dataclass

import asyncpg
from app.config import config
from app.utils.logger import get_logger
from app.utils.cache import AsyncCache

logger = get_logger(__name__)


@dataclass
class VectorSearchResult:
    """向量搜索结果"""
    content_id: str
    content_type: str
    similarity_score: float
    metadata: Dict[str, Any]
    embedding: Optional[List[float]] = None


class VectorService:
    """向量服务主类"""
    
    def __init__(self):
        self.db_pool: Optional[asyncpg.Pool] = None
        self.cache = AsyncCache()
        self.health_status = "initializing"
        self.vector_dimensions = config.vector.VECTOR_DIMENSIONS
        self.similarity_threshold = config.vector.VECTOR_SIMILARITY_THRESHOLD
        
    async def initialize(self):
        """初始化向量服务"""
        try:
            # 初始化数据库连接池
            self.db_pool = await asyncpg.create_pool(
                host=config.database.HOST,
                port=config.database.PORT,
                user=config.database.USER,
                password=config.database.PASSWORD,
                database=config.database.NAME,
                min_size=5,
                max_size=config.database.POOL_SIZE
            )
            
            # 验证数据库连接
            async with self.db_pool.acquire() as conn:
                await conn.execute("SELECT 1")
            
            # 初始化向量扩展
            await self._init_vector_extension()
            
            # 创建向量表
            await self._create_vector_tables()
            
            # 创建向量索引
            await self._create_vector_indexes()
            
            self.health_status = "healthy"
            logger.info("✅ 向量服务初始化完成")
            
        except Exception as e:
            self.health_status = "error"
            logger.error(f"❌ 向量服务初始化失败: {e}")
            raise
    
    async def cleanup(self):
        """清理资源"""
        try:
            if self.db_pool:
                await self.db_pool.close()
            logger.info("✅ 向量服务资源清理完成")
        except Exception as e:
            logger.error(f"❌ 向量服务资源清理失败: {e}")
    
    def is_healthy(self) -> bool:
        """检查服务健康状态"""
        return self.health_status == "healthy"
    
    async def _init_vector_extension(self):
        """初始化PostgreSQL向量扩展"""
        async with self.db_pool.acquire() as conn:
            # 检查pgvector扩展是否已安装
            result = await conn.fetchval(
                "SELECT COUNT(*) FROM pg_extension WHERE extname = 'vector'"
            )
            
            if result == 0:
                logger.info("📦 安装pgvector扩展...")
                await conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
                logger.info("✅ pgvector扩展安装完成")
            else:
                logger.info("✅ pgvector扩展已存在")
    
    async def _create_vector_tables(self):
        """创建向量相关表"""
        async with self.db_pool.acquire() as conn:
            # 创建向量嵌入表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS vector_embeddings (
                    id SERIAL PRIMARY KEY,
                    content_id VARCHAR(255) NOT NULL,
                    content_type VARCHAR(50) NOT NULL,
                    embedding vector(%s) NOT NULL,
                    metadata JSONB DEFAULT '{}',
                    model_version VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(content_id, content_type)
                )
            """, self.vector_dimensions)
            
            # 创建简历向量表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS resume_vectors (
                    id SERIAL PRIMARY KEY,
                    resume_id VARCHAR(255) UNIQUE NOT NULL,
                    embedding vector(%s) NOT NULL,
                    content_hash VARCHAR(64) NOT NULL,
                    analysis_data JSONB DEFAULT '{}',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, self.vector_dimensions)
            
            # 创建职位向量表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS job_vectors (
                    id SERIAL PRIMARY KEY,
                    job_id VARCHAR(255) UNIQUE NOT NULL,
                    embedding vector(%s) NOT NULL,
                    content_hash VARCHAR(64) NOT NULL,
                    job_data JSONB DEFAULT '{}',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, self.vector_dimensions)
            
            # 创建公司向量表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS company_vectors (
                    id SERIAL PRIMARY KEY,
                    company_id VARCHAR(255) UNIQUE NOT NULL,
                    embedding vector(%s) NOT NULL,
                    content_hash VARCHAR(64) NOT NULL,
                    company_data JSONB DEFAULT '{}',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, self.vector_dimensions)
            
            logger.info("✅ 向量表创建完成")
    
    async def _create_vector_indexes(self):
        """创建向量索引"""
        async with self.db_pool.acquire() as conn:
            # 为简历向量创建索引
            await conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_resume_vectors_embedding 
                ON resume_vectors 
                USING ivfflat (embedding vector_cosine_ops)
                WITH (lists = 100)
            """)
            
            # 为职位向量创建索引
            await conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_job_vectors_embedding 
                ON job_vectors 
                USING ivfflat (embedding vector_cosine_ops)
                WITH (lists = 100)
            """)
            
            # 为通用向量嵌入创建索引
            await conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_vector_embeddings_embedding 
                ON vector_embeddings 
                USING ivfflat (embedding vector_cosine_ops)
                WITH (lists = 100)
            """)
            
            logger.info("✅ 向量索引创建完成")
    
    async def store_resume_embedding(
        self,
        resume_id: str,
        embedding: List[float],
        content_hash: str,
        analysis_data: Optional[Dict[str, Any]] = None,
        model_version: str = "text-embedding-ada-002"
    ) -> bool:
        """存储简历向量嵌入"""
        try:
            async with self.db_pool.acquire() as conn:
                # 检查是否已存在
                existing = await conn.fetchval(
                    "SELECT id FROM resume_vectors WHERE resume_id = $1",
                    resume_id
                )
                
                if existing:
                    # 更新现有记录
                    await conn.execute("""
                        UPDATE resume_vectors 
                        SET embedding = $1, content_hash = $2, analysis_data = $3, updated_at = CURRENT_TIMESTAMP
                        WHERE resume_id = $4
                    """, embedding, content_hash, analysis_data or {}, resume_id)
                else:
                    # 插入新记录
                    await conn.execute("""
                        INSERT INTO resume_vectors (resume_id, embedding, content_hash, analysis_data)
                        VALUES ($1, $2, $3, $4)
                    """, resume_id, embedding, content_hash, analysis_data or {})
                
                # 同时存储到通用向量表
                await self._store_generic_embedding(
                    resume_id, "resume", embedding, 
                    {"content_hash": content_hash, "analysis_data": analysis_data},
                    model_version
                )
                
                logger.info(f"✅ 简历向量存储成功: {resume_id}")
                return True
                
        except Exception as e:
            logger.error(f"❌ 存储简历向量失败: {e}")
            return False
    
    async def store_job_embedding(
        self,
        job_id: str,
        embedding: List[float],
        content_hash: str,
        job_data: Optional[Dict[str, Any]] = None,
        model_version: str = "text-embedding-ada-002"
    ) -> bool:
        """存储职位向量嵌入"""
        try:
            async with self.db_pool.acquire() as conn:
                # 检查是否已存在
                existing = await conn.fetchval(
                    "SELECT id FROM job_vectors WHERE job_id = $1",
                    job_id
                )
                
                if existing:
                    # 更新现有记录
                    await conn.execute("""
                        UPDATE job_vectors 
                        SET embedding = $1, content_hash = $2, job_data = $3, updated_at = CURRENT_TIMESTAMP
                        WHERE job_id = $4
                    """, embedding, content_hash, job_data or {}, job_id)
                else:
                    # 插入新记录
                    await conn.execute("""
                        INSERT INTO job_vectors (job_id, embedding, content_hash, job_data)
                        VALUES ($1, $2, $3, $4)
                    """, job_id, embedding, content_hash, job_data or {})
                
                # 同时存储到通用向量表
                await self._store_generic_embedding(
                    job_id, "job", embedding, 
                    {"content_hash": content_hash, "job_data": job_data},
                    model_version
                )
                
                logger.info(f"✅ 职位向量存储成功: {job_id}")
                return True
                
        except Exception as e:
            logger.error(f"❌ 存储职位向量失败: {e}")
            return False
    
    async def _store_generic_embedding(
        self,
        content_id: str,
        content_type: str,
        embedding: List[float],
        metadata: Dict[str, Any],
        model_version: str
    ) -> bool:
        """存储通用向量嵌入"""
        try:
            async with self.db_pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO vector_embeddings (content_id, content_type, embedding, metadata, model_version)
                    VALUES ($1, $2, $3, $4, $5)
                    ON CONFLICT (content_id, content_type) 
                    DO UPDATE SET 
                        embedding = EXCLUDED.embedding,
                        metadata = EXCLUDED.metadata,
                        model_version = EXCLUDED.model_version,
                        updated_at = CURRENT_TIMESTAMP
                """, content_id, content_type, embedding, metadata, model_version)
                
                return True
                
        except Exception as e:
            logger.error(f"❌ 存储通用向量失败: {e}")
            return False
    
    async def similarity_search(
        self,
        query_embedding: List[float],
        content_type: str,
        limit: int = 10,
        similarity_threshold: Optional[float] = None
    ) -> List[VectorSearchResult]:
        """相似性搜索"""
        try:
            if similarity_threshold is None:
                similarity_threshold = self.similarity_threshold
            
            async with self.db_pool.acquire() as conn:
                # 使用余弦相似度搜索
                query = """
                    SELECT 
                        content_id,
                        content_type,
                        metadata,
                        embedding,
                        1 - (embedding <=> $1) as similarity_score
                    FROM vector_embeddings 
                    WHERE content_type = $2 
                        AND 1 - (embedding <=> $1) >= $3
                    ORDER BY embedding <=> $1
                    LIMIT $4
                """
                
                rows = await conn.fetch(
                    query, 
                    query_embedding, 
                    content_type, 
                    similarity_threshold, 
                    limit
                )
                
                results = []
                for row in rows:
                    result = VectorSearchResult(
                        content_id=row['content_id'],
                        content_type=row['content_type'],
                        similarity_score=float(row['similarity_score']),
                        metadata=row['metadata'],
                        embedding=row['embedding'].tolist() if row['embedding'] else None
                    )
                    results.append(result)
                
                logger.info(f"✅ 相似性搜索完成，找到 {len(results)} 个结果")
                return results
                
        except Exception as e:
            logger.error(f"❌ 相似性搜索失败: {e}")
            return []
    
    async def resume_job_match(
        self,
        resume_id: str,
        limit: int = 10,
        similarity_threshold: Optional[float] = None
    ) -> List[VectorSearchResult]:
        """简历与职位匹配"""
        try:
            # 获取简历向量
            resume_embedding = await self._get_resume_embedding(resume_id)
            if not resume_embedding:
                logger.warning(f"⚠️ 未找到简历向量: {resume_id}")
                return []
            
            # 搜索相似职位
            results = await self.similarity_search(
                query_embedding=resume_embedding,
                content_type="job",
                limit=limit,
                similarity_threshold=similarity_threshold
            )
            
            logger.info(f"✅ 简历职位匹配完成，找到 {len(results)} 个匹配职位")
            return results
            
        except Exception as e:
            logger.error(f"❌ 简历职位匹配失败: {e}")
            return []
    
    async def semantic_search(
        self,
        query: str,
        content_type: str,
        limit: int = 10,
        similarity_threshold: Optional[float] = None
    ) -> List[VectorSearchResult]:
        """语义搜索（需要先转换为向量）"""
        try:
            # 这里需要调用AI服务生成查询向量
            # 暂时返回空结果，实际使用时需要集成AI服务
            logger.info(f"🔍 语义搜索: {query} -> {content_type}")
            
            # TODO: 集成AI服务生成查询向量
            # query_embedding = await ai_service.generate_embeddings(query)
            # return await self.similarity_search(query_embedding, content_type, limit, similarity_threshold)
            
            return []
            
        except Exception as e:
            logger.error(f"❌ 语义搜索失败: {e}")
            return []
    
    async def _get_resume_embedding(self, resume_id: str) -> Optional[List[float]]:
        """获取简历向量"""
        try:
            async with self.db_pool.acquire() as conn:
                row = await conn.fetchrow(
                    "SELECT embedding FROM resume_vectors WHERE resume_id = $1",
                    resume_id
                )
                
                if row:
                    return row['embedding'].tolist()
                return None
                
        except Exception as e:
            logger.error(f"❌ 获取简历向量失败: {e}")
            return None
    
    async def get_vector_stats(self) -> Dict[str, Any]:
        """获取向量统计信息"""
        try:
            async with self.db_pool.acquire() as conn:
                stats = {}
                
                # 统计各类型向量数量
                for content_type in ['resume', 'job', 'company']:
                    count = await conn.fetchval(
                        "SELECT COUNT(*) FROM vector_embeddings WHERE content_type = $1",
                        content_type
                    )
                    stats[f"{content_type}_count"] = count
                
                # 统计总向量数量
                total_count = await conn.fetchval(
                    "SELECT COUNT(*) FROM vector_embeddings"
                )
                stats['total_count'] = total_count
                
                # 统计存储大小（估算）
                size_query = """
                    SELECT pg_size_pretty(pg_total_relation_size('vector_embeddings')) as size
                """
                size_row = await conn.fetchrow(size_query)
                stats['storage_size'] = size_row['size'] if size_row else 'Unknown'
                
                # 统计最近更新时间
                latest_update = await conn.fetchval(
                    "SELECT MAX(updated_at) FROM vector_embeddings"
                )
                stats['latest_update'] = latest_update.isoformat() if latest_update else None
                
                return stats
                
        except Exception as e:
            logger.error(f"❌ 获取向量统计失败: {e}")
            return {}
    
    async def cleanup_old_vectors(self, days: int = 30) -> int:
        """清理旧的向量数据"""
        try:
            async with self.db_pool.acquire() as conn:
                # 删除超过指定天数的向量数据
                result = await conn.execute("""
                    DELETE FROM vector_embeddings 
                    WHERE updated_at < CURRENT_TIMESTAMP - INTERVAL '$1 days'
                """, days)
                
                deleted_count = int(result.split()[-1])
                logger.info(f"✅ 清理了 {deleted_count} 个旧向量")
                return deleted_count
                
        except Exception as e:
            logger.error(f"❌ 清理旧向量失败: {e}")
            return 0
    
    async def rebuild_indexes(self) -> bool:
        """重建向量索引"""
        try:
            async with self.db_pool.acquire() as conn:
                # 删除现有索引
                await conn.execute("DROP INDEX IF EXISTS idx_resume_vectors_embedding")
                await conn.execute("DROP INDEX IF EXISTS idx_job_vectors_embedding")
                await conn.execute("DROP INDEX IF EXISTS idx_vector_embeddings_embedding")
                
                # 重新创建索引
                await self._create_vector_indexes()
                
                logger.info("✅ 向量索引重建完成")
                return True
                
        except Exception as e:
            logger.error(f"❌ 重建向量索引失败: {e}")
            return False
