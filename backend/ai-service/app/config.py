"""
JobFirst AI服务配置管理
"""

import os
from typing import Dict, Any
from dataclasses import dataclass, asdict, field


@dataclass
class DatabaseConfig:
    """数据库配置"""
    HOST: str = os.getenv("DB_HOST", "localhost")
    PORT: int = int(os.getenv("DB_PORT", "5432"))
    NAME: str = os.getenv("DB_NAME", "jobfirst")
    USER: str = os.getenv("DB_USER", "postgres")
    PASSWORD: str = os.getenv("DB_PASSWORD", "")
    SSL_MODE: str = os.getenv("DB_SSL_MODE", "disable")
    POOL_SIZE: int = int(os.getenv("DB_POOL_SIZE", "20"))
    MAX_OVERFLOW: int = int(os.getenv("DB_MAX_OVERFLOW", "30"))
    
    @property
    def connection_string(self) -> str:
        """构建数据库连接字符串"""
        return f"postgresql://{self.USER}:{self.PASSWORD}@{self.HOST}:{self.PORT}/{self.NAME}?sslmode={self.SSL_MODE}"


@dataclass
class RedisConfig:
    """Redis配置"""
    HOST: str = os.getenv("REDIS_HOST", "localhost")
    PORT: int = int(os.getenv("REDIS_PORT", "6379"))
    DB: int = int(os.getenv("REDIS_DB", "0"))
    PASSWORD: str = os.getenv("REDIS_PASSWORD", "")
    SSL: bool = os.getenv("REDIS_SSL", "false").lower() == "true"
    
    @property
    def connection_string(self) -> str:
        """构建Redis连接字符串"""
        protocol = "rediss" if self.SSL else "redis"
        auth = f":{self.PASSWORD}@" if self.PASSWORD else ""
        return f"{protocol}://{auth}{self.HOST}:{self.PORT}/{self.DB}"


@dataclass
class AIConfig:
    """AI服务配置"""
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4")
    OPENAI_MAX_TOKENS: int = int(os.getenv("OPENAI_MAX_TOKENS", "4000"))
    OPENAI_TEMPERATURE: float = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))
    
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")
    ANTHROPIC_MODEL: str = os.getenv("ANTHROPIC_MODEL", "claude-3-sonnet-20240229")
    
    # 本地模型配置
    LOCAL_MODEL_PATH: str = os.getenv("LOCAL_MODEL_PATH", "")
    LOCAL_MODEL_DEVICE: str = os.getenv("LOCAL_MODEL_DEVICE", "cpu")
    
    # 向量模型配置
    EMBEDDING_MODEL: str = os.getenv("EMBEDDING_MODEL", "text-embedding-ada-002")
    EMBEDDING_DIMENSIONS: int = int(os.getenv("EMBEDDING_DIMENSIONS", "1536"))
    
    # 分析配置
    MAX_RESUME_LENGTH: int = int(os.getenv("MAX_RESUME_LENGTH", "10000"))
    ANALYSIS_TIMEOUT: int = int(os.getenv("ANALYSIS_TIMEOUT", "300"))
    BATCH_SIZE: int = int(os.getenv("BATCH_SIZE", "10"))


@dataclass
class VectorConfig:
    """向量数据库配置"""
    VECTOR_DB_TYPE: str = os.getenv("VECTOR_DB_TYPE", "postgresql")  # postgresql, faiss, chroma
    VECTOR_INDEX_TYPE: str = os.getenv("VECTOR_INDEX_TYPE", "ivfflat")  # ivfflat, hnsw
    VECTOR_METRIC: str = os.getenv("VECTOR_METRIC", "cosine")  # cosine, euclidean, dot_product
    VECTOR_DIMENSIONS: int = int(os.getenv("VECTOR_DIMENSIONS", "1536"))
    VECTOR_SIMILARITY_THRESHOLD: float = float(os.getenv("VECTOR_SIMILARITY_THRESHOLD", "0.7"))
    VECTOR_MAX_RESULTS: int = int(os.getenv("VECTOR_MAX_RESULTS", "100"))


@dataclass
class SecurityConfig:
    """安全配置"""
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-here")
    JWT_SECRET: str = os.getenv("JWT_SECRET", "your-jwt-secret-here")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRE_MINUTES: int = int(os.getenv("JWT_EXPIRE_MINUTES", "30"))
    
    # CORS配置
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "*")
    CORS_METHODS: str = os.getenv("CORS_METHODS", "GET,POST,PUT,DELETE,OPTIONS")
    CORS_HEADERS: str = os.getenv("CORS_HEADERS", "*")
    
    # 限流配置
    RATE_LIMIT_ENABLED: bool = os.getenv("RATE_LIMIT_ENABLED", "true").lower() == "true"
    RATE_LIMIT_REQUESTS: int = int(os.getenv("RATE_LIMIT_REQUESTS", "100"))
    RATE_LIMIT_WINDOW: int = int(os.getenv("RATE_LIMIT_WINDOW", "60"))


@dataclass
class MonitoringConfig:
    """监控配置"""
    PROMETHEUS_ENABLED: bool = os.getenv("PROMETHEUS_ENABLED", "true").lower() == "true"
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT: str = os.getenv("LOG_FORMAT", "json")
    LOG_FILE: str = os.getenv("LOG_FILE", "")
    
    # 性能监控
    ENABLE_PROFILING: bool = os.getenv("ENABLE_PROFILING", "false").lower() == "true"
    ENABLE_METRICS: bool = os.getenv("ENABLE_METRICS", "true").lower() == "true"


@dataclass
class Config:
    """主配置类"""
    # 服务配置
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8001"))
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    WORKERS: int = int(os.getenv("WORKERS", "4"))
    ACCESS_LOG: bool = os.getenv("ACCESS_LOG", "true").lower() == "true"
    
    # 环境
    ENV: str = os.getenv("ENV", "development")
    
    # 子配置
    database: DatabaseConfig = field(default_factory=DatabaseConfig)
    redis: RedisConfig = field(default_factory=RedisConfig)
    ai: AIConfig = field(default_factory=AIConfig)
    vector: VectorConfig = field(default_factory=VectorConfig)
    security: SecurityConfig = field(default_factory=SecurityConfig)
    monitoring: MonitoringConfig = field(default_factory=MonitoringConfig)
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典格式"""
        return asdict(self)
    
    @classmethod
    def from_env(cls) -> 'Config':
        """从环境变量创建配置"""
        return cls()
    
    def validate(self) -> bool:
        """验证配置有效性"""
        errors = []
        
        # 验证必要的配置
        if not self.database.PASSWORD:
            errors.append("数据库密码不能为空")
        
        if not self.ai.OPENAI_API_KEY and not self.ai.ANTHROPIC_API_KEY:
            errors.append("至少需要配置一个AI服务的API密钥")
        
        if not self.security.SECRET_KEY or self.security.SECRET_KEY == "your-secret-key-here":
            errors.append("请设置安全的SECRET_KEY")
        
        if errors:
            raise ValueError(f"配置验证失败: {'; '.join(errors)}")
        
        return True


# 全局配置实例
config = Config.from_env()

# 验证配置
try:
    config.validate()
except ValueError as e:
    print(f"❌ 配置错误: {e}")
    exit(1)
