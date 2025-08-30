# Docker环境中的所有数据库分析报告

## 概述

在Docker环境中发现了5个数据库容器，包括MySQL、Redis和PostgreSQL数据库。以下是详细的分析结果。

## 数据库容器列表

| 容器名称 | 数据库类型 | 版本 | 状态 | 用途 |
|----------|------------|------|------|------|
| jobfirst-mysql | MySQL | 8.0 | Up 27 minutes | JobFirst简历中心系统 |
| jobfirst-redis | Redis | 7-alpine | Up 27 minutes | JobFirst缓存系统 |
| talent_shared_mysql | MySQL | 8.0 | Up 11 hours | 人才共享平台主数据库 |
| talent_shared_redis | Redis | 7-alpine | Up 11 hours | 人才共享平台缓存 |
| talent_shared_kong_db | PostgreSQL | 13 | Up 11 hours | Kong API网关配置 |

## 1. JobFirst MySQL 数据库 (jobfirst-mysql)

### 基本信息
- **数据库名**: jobfirst
- **用户名**: jobfirst / root
- **密码**: jobfirst123 / jobfirst123
- **总表数**: 23个
- **有数据的表**: 1个 (resume_templates)

### 主要模块
- **用户管理**: users, user_behaviors
- **简历管理**: resumes, resume_templates, resume_banners
- **积分系统**: points, point_records, points_rules
- **文件存储**: files, file_shares, file_versions, file_access_logs, storage_quota
- **统计分析**: statistics, statistics_events, real_time_stats

### 初始数据
- **简历模板**: 3个 (经典商务、创意设计、技术开发)
- **积分规则**: 5个 (注册、登录、创建简历、分享、下载模板)

## 2. JobFirst Redis 数据库 (jobfirst-redis)

### 基本信息
- **版本**: Redis 7-alpine
- **状态**: 运行中，无密码保护
- **当前数据**: 空 (无键值对)

### 用途
- 缓存用户会话
- 存储临时数据
- 限流计数器
- 分布式锁

## 3. Talent Shared MySQL 数据库 (talent_shared_mysql)

### 基本信息
- **数据库名**: talent_shared
- **用户名**: root
- **密码**: talent_root123
- **总表数**: 14个
- **有数据的表**: 4个

### 表结构分析

#### 核心业务表
1. **users** (2条记录)
   - 用户管理，包含admin和manager用户
   - 角色: admin, manager, recruiter, viewer

2. **ai_models** (4条记录)
   - AI模型管理
   - 模型类型: embedding, classification, recommendation, qa, generation
   - 提供商: openai, huggingface

3. **system_configs** (8条记录)
   - 系统配置管理
   - 配置类型: string, number, boolean, json, array

4. **service_health** (7条记录)
   - 服务健康状态监控

#### 功能支持表
- **activity**: 用户活动记录
- **ai_inference_logs**: AI推理日志
- **audit_logs**: 审计日志
- **cache_management**: 缓存管理
- **geo_locations**: 地理位置数据
- **monitoring_metrics**: 监控指标
- **sync_logs**: 同步日志
- **translation_services**: 翻译服务
- **vaults**: 密钥存储

### 数据详情

#### AI模型配置
| ID | 模型名称 | 类型 | 提供商 | 状态 |
|----|----------|------|--------|------|
| 1 | text-embedding-ada-002 | embedding | openai | 启用 |
| 2 | gpt-4 | generation | openai | 启用 |
| 3 | sentence-transformers | embedding | huggingface | 启用 |
| 4 | bert-base-chinese | classification | huggingface | 启用 |

#### 系统配置
| 配置键 | 类型 | 描述 |
|--------|------|------|
| system_name | string | 系统名称 |
| system_version | string | 系统版本 |
| ai_enabled | boolean | 是否启用AI功能 |
| max_search_results | number | 最大搜索结果数 |
| cache_ttl_default | number | 默认缓存生存时间(秒) |
| monitoring_enabled | boolean | 是否启用监控 |
| log_level | string | 日志级别 |
| api_rate_limit | json | API限流配置 |

## 4. Talent Shared Redis 数据库 (talent_shared_redis)

### 基本信息
- **版本**: Redis 7-alpine
- **状态**: 运行中，需要认证
- **配置**: 启用AOF持久化

### 用途
- 缓存系统配置
- 存储会话数据
- 限流计数器
- 临时数据存储

## 5. Kong API网关数据库 (talent_shared_kong_db)

### 基本信息
- **数据库类型**: PostgreSQL 13
- **数据库名**: kong
- **用户名**: kong
- **总表数**: 32个

### 配置的服务
| 服务名称 | 主机 | 端口 | 协议 |
|----------|------|------|------|
| ai-model-manager | talent_shared_ai_model_manager | 8081 | http |
| health-checker | talent_shared_health_checker | 8080 | http |
| data-sync | talent_shared_data_sync | 8080 | http |

### 配置的路由
| 路由名称 | 路径 | 对应服务 |
|----------|------|----------|
| ai-model-manager-route | `/ai-models`, `/ai-models/` | ai-model-manager |
| health-checker-route | `/health`, `/health/` | health-checker |
| data-sync-route | `/data-sync`, `/data-sync/` | data-sync |

## 系统架构分析

### 整体架构
这是一个多系统的微服务架构，包含：

1. **JobFirst简历中心系统**
   - MySQL数据库: 业务数据存储
   - Redis缓存: 性能优化
   - 微服务架构: 用户、简历、积分、存储、统计

2. **Talent Shared人才共享平台**
   - MySQL数据库: 核心业务数据
   - Redis缓存: 系统缓存
   - AI模型管理: 多种AI服务集成

3. **Kong API网关**
   - PostgreSQL数据库: 网关配置
   - 统一入口: 服务路由和负载均衡
   - 安全控制: 认证、授权、限流

### 数据流向
```
用户请求 → Kong API网关 → 后端服务 → 数据库
                ↓
            Redis缓存 ← 数据缓存
```

## 数据统计汇总

| 数据库 | 表数 | 有数据表数 | 总记录数 | 主要功能 |
|--------|------|------------|----------|----------|
| jobfirst | 23 | 1 | 3 | 简历管理系统 |
| talent_shared | 14 | 4 | 21 | 人才共享平台 |
| kong | 32 | 3 | 6 | API网关配置 |
| jobfirst-redis | - | 0 | 0 | 缓存系统 |
| talent_shared_redis | - | 需要认证 | - | 缓存系统 |

## 导出建议

### 1. 数据库备份
```bash
# JobFirst MySQL
docker exec jobfirst-mysql mysqldump -u root -pjobfirst123 jobfirst > jobfirst_backup.sql

# Talent Shared MySQL
docker exec talent_shared_mysql mysqldump -u root -ptalent_root123 talent_shared > talent_shared_backup.sql

# Kong PostgreSQL
docker exec talent_shared_kong_db pg_dump -U kong kong > kong_backup.sql
```

### 2. 数据迁移策略
1. **JobFirst系统**: 独立的简历管理系统，可以单独迁移
2. **Talent Shared系统**: 人才共享平台，包含AI功能
3. **Kong网关**: 可以复用或重新配置

### 3. 集成建议
- 考虑将JobFirst集成到Talent Shared平台
- 利用现有的AI模型和配置
- 统一使用Kong API网关
- 共享用户认证和权限系统

## 总结

这个Docker环境包含了一个完整的微服务生态系统：

1. **JobFirst**: 专业的简历管理系统
2. **Talent Shared**: 综合性人才管理平台
3. **Kong**: 企业级API网关

为二次开发提供了：
- 完整的用户管理系统
- 丰富的AI模型配置
- 企业级API网关架构
- 可扩展的微服务框架

建议根据具体需求选择合适的组件进行集成和扩展。
