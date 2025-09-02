# JobFirst AI Service

基于Python Sanic的高性能异步AI服务，提供简历分析、优化和向量搜索功能。

## 🚀 特性

- **高性能异步架构**: 基于Sanic框架，支持高并发处理
- **多AI模型集成**: 支持OpenAI GPT-4、Claude等大模型
- **向量数据库**: 集成PostgreSQL + pgvector，支持语义搜索
- **智能简历分析**: AI驱动的简历评分和优化建议
- **微服务架构**: 与现有Golang服务无缝集成
- **监控和日志**: 完整的Prometheus指标和结构化日志

## 🏗️ 架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   AI Service    │
│   (Next.js)     │◄──►│   (Golang)      │◄──►│   (Python)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   User Service  │    │  PostgreSQL     │
                       │   (Golang)      │    │  + pgvector     │
                       └─────────────────┘    └─────────────────┘
```

## 📋 系统要求

- Python 3.11+
- PostgreSQL 15+ with pgvector extension
- Redis 7+
- 8GB+ RAM (推荐16GB)
- 4+ CPU cores

## 🛠️ 安装

### 1. 克隆项目
```bash
git clone <repository-url>
cd jobfirst/backend/ai-service
```

### 2. 创建虚拟环境
```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
venv\Scripts\activate     # Windows
```

### 3. 安装依赖
```bash
pip install -r requirements.txt
```

### 4. 配置环境变量
```bash
cp .env.example .env
# 编辑 .env 文件，填入必要的配置
```

### 5. 启动服务
```bash
# 使用启动脚本
chmod +x start.sh
./start.sh

# 或直接启动
python main.py
```

## 🐳 Docker部署

### 1. 构建镜像
```bash
docker build -t jobfirst-ai-service .
```

### 2. 使用docker-compose
```bash
docker-compose up -d
```

### 3. 查看服务状态
```bash
docker-compose ps
docker-compose logs -f ai-service
```

## 🔧 配置

### 环境变量

| 变量名 | 描述 | 默认值 | 必需 |
|--------|------|--------|------|
| `OPENAI_API_KEY` | OpenAI API密钥 | - | ✅ |
| `DB_PASSWORD` | 数据库密码 | - | ✅ |
| `HOST` | 服务监听地址 | 0.0.0.0 | ❌ |
| `PORT` | 服务端口 | 8001 | ❌ |
| `WORKERS` | 工作进程数 | 4 | ❌ |

### AI模型配置

支持多种AI模型，可根据需求配置：

- **OpenAI**: GPT-4, GPT-3.5-turbo
- **Anthropic**: Claude-3-Sonnet, Claude-3-Haiku
- **本地模型**: 支持Hugging Face模型

## 📚 API接口

### 简历分析
```http
POST /api/v1/ai/resume/analyze
Content-Type: application/json

{
  "resume_id": "resume_123",
  "content": "简历内容...",
  "analysis_type": "comprehensive",
  "target_job": "软件工程师",
  "industry": "互联网"
}
```

### 简历优化
```http
POST /api/v1/ai/resume/optimize
Content-Type: application/json

{
  "resume_id": "resume_123",
  "analysis_id": "analysis_456",
  "optimization_focus": "skills",
  "target_job": "高级软件工程师"
}
```

### 向量搜索
```http
POST /api/v1/vector/search
Content-Type: application/json

{
  "query_embedding": [0.1, 0.2, ...],
  "content_type": "job",
  "limit": 10,
  "similarity_threshold": 0.7
}
```

## 🔍 监控和日志

### 健康检查
```bash
curl http://localhost:8001/health
```

### 监控指标
```bash
curl http://localhost:8001/metrics
```

### 日志查看
```bash
# 查看实时日志
tail -f logs/ai-service.log

# 查看Docker日志
docker-compose logs -f ai-service
```

## 🧪 测试

### 运行测试
```bash
# 安装测试依赖
pip install pytest pytest-asyncio

# 运行测试
pytest tests/ -v
```

### 性能测试
```bash
# 使用ab进行压力测试
ab -n 1000 -c 10 http://localhost:8001/health

# 使用wrk进行性能测试
wrk -t12 -c400 -d30s http://localhost:8001/health
```

## 🚨 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查PostgreSQL服务状态
   - 验证数据库连接参数
   - 确认pgvector扩展已安装

2. **AI模型调用失败**
   - 检查API密钥配置
   - 验证网络连接
   - 查看API配额限制

3. **向量搜索性能问题**
   - 检查向量索引状态
   - 优化相似度阈值
   - 考虑重建索引

### 日志分析
```bash
# 查看错误日志
grep "ERROR" logs/ai-service.log

# 查看性能日志
grep "Response-Time" logs/ai-service.log
```

## 📈 性能优化

### 数据库优化
- 使用连接池管理数据库连接
- 定期重建向量索引
- 监控慢查询

### AI服务优化
- 启用结果缓存
- 批量处理请求
- 异步处理长任务

### 系统优化
- 调整工作进程数
- 配置内存限制
- 启用压缩

## 🤝 贡献

1. Fork项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持

如有问题或建议，请：

- 提交Issue
- 发送邮件至: support@jobfirst.com
- 查看文档: https://docs.jobfirst.com

## 🔄 更新日志

### v1.0.0 (2025-01-02)
- 初始版本发布
- 支持OpenAI和Anthropic模型
- 集成PostgreSQL向量数据库
- 完整的简历分析功能

---

**JobFirst AI Service** - 让AI为你的职业发展助力！ 🚀
