# PostgreSQL Kong API网关数据库分析

## 概述

在Docker环境中发现了一个PostgreSQL数据库，用于存储Kong API网关的配置信息。

## 数据库信息

- **容器名称**: `talent_shared_kong_db`
- **数据库类型**: PostgreSQL 13
- **数据库名称**: `kong`
- **用户名**: `kong`
- **用途**: Kong API网关配置存储

## 数据库列表

| 数据库名 | 所有者 | 编码 | 排序规则 | 字符类型 |
|----------|--------|------|----------|----------|
| kong | kong | UTF8 | en_US.utf8 | en_US.utf8 |
| postgres | kong | UTF8 | en_US.utf8 | en_US.utf8 |
| template0 | kong | UTF8 | en_US.utf8 | en_US.utf8 |
| template1 | kong | UTF8 | en_US.utf8 | en_US.utf8 |

## 表结构分析

### 核心表 (32个表)

#### 1. 服务管理表
- **services**: 后端服务配置
- **routes**: 路由规则配置
- **upstreams**: 上游服务配置
- **targets**: 目标服务配置

#### 2. 认证授权表
- **consumers**: 消费者/用户
- **basicauth_credentials**: 基本认证凭据
- **hmacauth_credentials**: HMAC认证凭据
- **jwt_secrets**: JWT密钥
- **keyauth_credentials**: 密钥认证凭据
- **oauth2_credentials**: OAuth2凭据
- **oauth2_authorization_codes**: OAuth2授权码
- **oauth2_tokens**: OAuth2令牌

#### 3. 插件配置表
- **plugins**: 插件配置
- **parameters**: 参数配置
- **filter_chains**: 过滤器链

#### 4. 安全相关表
- **certificates**: 证书
- **ca_certificates**: CA证书
- **snis**: SNI配置
- **keys**: 密钥
- **key_sets**: 密钥集

#### 5. 监控统计表
- **ratelimiting_metrics**: 限流指标
- **response_ratelimiting_metrics**: 响应限流指标
- **cluster_events**: 集群事件
- **clustering_data_planes**: 数据平面集群

#### 6. 系统管理表
- **workspaces**: 工作空间
- **tags**: 标签
- **locks**: 锁
- **sessions**: 会话
- **acme_storage**: ACME存储
- **sm_vaults**: 密钥管理存储
- **schema_meta**: 模式元数据

## 当前配置的服务

### 1. AI模型管理服务
```sql
{
    "id": "5b4fcc16-b7e4-4c42-b921-5bd14d69e8aa",
    "name": "ai-model-manager",
    "host": "talent_shared_ai_model_manager",
    "port": 8081,
    "protocol": "http",
    "enabled": true
}
```

### 2. 健康检查服务
```sql
{
    "id": "404229a6-5fa5-44f9-a9da-12aff5107ad7",
    "name": "health-checker",
    "host": "talent_shared_health_checker",
    "port": 8080,
    "protocol": "http",
    "enabled": true
}
```

### 3. 数据同步服务
```sql
{
    "id": "96a4476b-fc5b-4b1e-bc36-dc435bdc73e5",
    "name": "data-sync",
    "host": "talent_shared_data_sync",
    "port": 8080,
    "protocol": "http",
    "enabled": true
}
```

## 当前配置的路由

### 1. AI模型管理路由
```sql
{
    "id": "8533a259-7f4a-4390-ac5f-4d448fe8bc42",
    "name": "ai-model-manager-route",
    "paths": ["/ai-models", "/ai-models/"],
    "service_name": "ai-model-manager"
}
```

### 2. 健康检查路由
```sql
{
    "id": "4d41e489-4fdb-4a95-8959-4496e84ba736",
    "name": "health-checker-route",
    "paths": ["/health", "/health/"],
    "service_name": "health-checker"
}
```

### 3. 数据同步路由
```sql
{
    "id": "226e37eb-fdeb-4589-abc9-ba1373378330",
    "name": "data-sync-route",
    "paths": ["/data-sync", "/data-sync/"],
    "service_name": "data-sync"
}
```

## 关键表结构

### services 表结构
```sql
CREATE TABLE services (
    id uuid PRIMARY KEY,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name text,
    retries bigint,
    protocol text,
    host text,
    port bigint,
    path text,
    connect_timeout bigint,
    write_timeout bigint,
    read_timeout bigint,
    tags text[],
    client_certificate_id uuid,
    tls_verify boolean,
    tls_verify_depth smallint,
    ca_certificates uuid[],
    ws_id uuid,
    enabled boolean DEFAULT true
);
```

### routes 表结构
```sql
CREATE TABLE routes (
    id uuid PRIMARY KEY,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name text,
    service_id uuid,
    protocols text[],
    methods text[],
    hosts text[],
    paths text[],
    snis text[],
    sources jsonb[],
    destinations jsonb[],
    regex_priority bigint,
    strip_path boolean,
    preserve_host boolean,
    tags text[],
    https_redirect_status_code integer,
    headers jsonb,
    path_handling text DEFAULT 'v0',
    ws_id uuid,
    request_buffering boolean,
    response_buffering boolean,
    expression text,
    priority bigint
);
```

## 数据统计

- **总表数**: 32个
- **配置的服务**: 3个
- **配置的路由**: 3个
- **配置的插件**: 0个
- **注册的消费者**: 0个
- **配置的证书**: 0个

## 系统架构分析

### 微服务架构
从配置可以看出，这是一个基于Kong API网关的微服务架构：

1. **API网关**: Kong作为统一的API入口
2. **服务发现**: 通过Docker容器名称进行服务发现
3. **路由管理**: 基于路径的路由规则
4. **服务监控**: 健康检查服务

### 服务组件
1. **AI模型管理服务**: 端口8081，提供AI模型相关功能
2. **健康检查服务**: 端口8080，提供系统健康监控
3. **数据同步服务**: 端口8080，提供数据同步功能

## 与JobFirst系统的关系

这个PostgreSQL数据库是Kong API网关的配置存储，与JobFirst简历中心系统可能存在以下关系：

1. **API网关**: 可能为JobFirst系统提供API网关功能
2. **服务集成**: 可能集成JobFirst的微服务
3. **统一入口**: 为多个系统提供统一的API入口
4. **安全控制**: 提供认证、授权、限流等安全功能

## 导出建议

### 1. 配置备份
```bash
# 备份Kong配置
docker exec talent_shared_kong_db pg_dump -U kong kong > kong_config_backup.sql
```

### 2. 服务配置导出
```sql
-- 导出服务配置
SELECT 
    name,
    host,
    port,
    protocol,
    enabled,
    created_at
FROM services
ORDER BY name;
```

### 3. 路由配置导出
```sql
-- 导出路由配置
SELECT 
    r.name as route_name,
    r.paths,
    s.name as service_name,
    s.host,
    s.port
FROM routes r
JOIN services s ON r.service_id = s.id
ORDER BY r.name;
```

## 总结

这个PostgreSQL数据库是Kong API网关的配置存储，为微服务架构提供：

1. **API网关功能**: 统一入口、路由管理
2. **服务管理**: 后端服务配置和发现
3. **安全控制**: 认证、授权、限流
4. **监控能力**: 健康检查、指标收集

建议在JobFirst系统的二次开发中考虑：
- 是否需要集成Kong API网关
- 如何配置JobFirst服务的路由规则
- 是否需要添加认证和授权功能
- 如何实现服务监控和健康检查
