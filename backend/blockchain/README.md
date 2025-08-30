# Resume Centre 腾讯云区块链服务

## 概述

这是Resume Centre项目的区块链微服务，已从华为云区块链服务迁移到腾讯云区块链服务。该服务提供区块链证书管理、积分交易、简历存储等功能。

## 功能特性

### 核心功能
- ✅ 区块链证书管理
- ✅ 积分交易记录
- ✅ 简历区块链存储
- ✅ 智能合约管理
- ✅ 钱包管理
- ✅ 交易记录查询

### 腾讯云区块链集成
- ✅ 腾讯云TBaaS服务集成
- ✅ 智能合约调用
- ✅ 交易查询
- ✅ 区块信息查询
- ✅ 集群管理

## 技术栈

- **语言**: Go 1.21+
- **Web框架**: Gin
- **数据库**: MySQL + GORM
- **缓存**: Redis
- **服务发现**: Consul
- **区块链**: 腾讯云TBaaS
- **容器化**: Docker

## 快速开始

### 前置要求

1. **腾讯云账号和API密钥**
   - 腾讯云SecretId和SecretKey
   - 腾讯云TBaaS区块链集群
   - 区块链通道和智能合约

2. **本地开发环境**
   - Go 1.21+
   - Docker & Docker Compose
   - MySQL 8.0+
   - Redis 7.0+

### 配置腾讯云区块链

1. **创建腾讯云TBaaS集群**
   ```bash
   # 登录腾讯云控制台
   # 进入TBaaS服务
   # 创建区块链网络
   ```

2. **配置环境变量**
   ```bash
   export TENCENT_SECRET_ID="your_secret_id"
   export TENCENT_SECRET_KEY="your_secret_key"
   export TENCENT_REGION="ap-guangzhou"
   export TENCENT_CLUSTER_ID="your_cluster_id"
   export TENCENT_CHANNEL_ID="your_channel_id"
   export TENCENT_CHAINCODE_ID="your_chaincode_id"
   ```

3. **更新配置文件**
   ```yaml
   # config.yaml
   tencent:
     secret_id: "your_secret_id"
     secret_key: "your_secret_key"
     region: "ap-guangzhou"
     blockchain:
       cluster_id: "your_cluster_id"
       channel_id: "your_channel_id"
       chaincode_id: "your_chaincode_id"
   ```

### 启动服务

1. **使用Docker Compose**
   ```bash
   docker-compose up -d blockchain-service
   ```

2. **本地开发**
   ```bash
   cd go-services/blockchain
   go mod tidy
   go run main.go
   ```

## API接口

### 区块链证书管理

#### 创建证书
```bash
POST /api/v1/certificates/
Content-Type: application/json

{
  "type": "resume",
  "title": "我的简历证书",
  "description": "区块链简历证书",
  "content": "证书内容...",
  "blockchain_type": "tencent"
}
```

#### 查询证书列表
```bash
GET /api/v1/certificates/?type=resume&status=confirmed
```

#### 验证证书
```bash
GET /api/v1/certificates/{id}/verify
```

### 积分交易管理

#### 保存积分交易
```bash
POST /api/v1/points/tx
Content-Type: application/json

{
  "fromUserId": "user123",
  "fromUserSource": 2,
  "toUserId": "user456",
  "toUserSource": 2,
  "transactionPoint": 100,
  "transactionCode": 1,
  "transactionContent": "积分转账"
}
```

#### 查询积分余额
```bash
GET /api/v1/points/balance/{userId}
```

#### 积分转账
```bash
POST /api/v1/points/transfer
Content-Type: application/json

{
  "fromUserId": "user123",
  "toUserId": "user456",
  "points": 50
}
```

### 简历区块链存储

#### 创建简历
```bash
POST /api/v1/resume/?resumeId=resume123
Content-Type: application/json

{
  "userId": "user123",
  "title": "我的简历",
  "content": "简历内容..."
}
```

#### 查询简历
```bash
GET /api/v1/resume/{id}
```

#### 删除简历
```bash
DELETE /api/v1/resume/{id}
```

### 智能合约管理

#### 部署合约
```bash
POST /api/v1/contracts/
Content-Type: application/json

{
  "name": "积分合约",
  "blockchain_type": "tencent",
  "abi": "[...]",
  "bytecode": "0x...",
  "version": "1.0.0"
}
```

#### 调用合约
```bash
POST /api/v1/contracts/{id}/invoke
Content-Type: application/json

{
  "function": "transfer",
  "args": ["from", "to", "100"]
}
```

#### 查询合约
```bash
POST /api/v1/contracts/{id}/query
Content-Type: application/json

{
  "function": "balanceOf",
  "args": ["user123"]
}
```

## 数据库模型

### 主要数据表

1. **blockchain_certificates** - 区块链证书
2. **blockchain_transactions** - 区块链交易
3. **wallets** - 钱包信息
4. **smart_contracts** - 智能合约
5. **blockchain_configs** - 区块链配置
6. **points_transaction_histories** - 积分交易历史
7. **resume_models** - 简历模型

### 自动迁移

服务启动时会自动创建所需的数据表：

```go
db.AutoMigrate(
    &BlockchainCertificate{},
    &BlockchainTransaction{},
    &Wallet{},
    &SmartContract{},
    &BlockchainConfig{},
    &PointsTransactionHistory{},
)
```

## 腾讯云区块链集成

### 智能合约函数

#### 积分相关
- `savePointsTransaction` - 保存积分交易
- `transferPoints` - 积分转账
- `getPointsBalance` - 查询积分余额

#### 简历相关
- `createResume` - 创建简历
- `getResume` - 查询简历
- `deleteResume` - 删除简历

#### 证书相关
- `createCertificate` - 创建证书
- `verifyCertificate` - 验证证书

### 错误处理

```go
// 腾讯云API错误处理
func handleTencentCloudError(err error) error {
    if tencentErr, ok := err.(*errors.TencentCloudSDKError); ok {
        return fmt.Errorf("Tencent Cloud API error: %s, Code: %s", 
            tencentErr.Message, tencentErr.Code)
    }
    return err
}
```

## 监控和日志

### 健康检查
```bash
GET /health
```

响应示例：
```json
{
  "status": "healthy",
  "service": "blockchain",
  "timestamp": 1703123456,
  "version": "2.0.0",
  "provider": "tencent-cloud"
}
```

### 日志配置
```yaml
logging:
  level: "info"
  format: "json"
  output: "stdout"
```

## 部署

### Docker部署
```bash
# 构建镜像
docker build -t resume-centre-blockchain .

# 运行容器
docker run -d \
  --name blockchain-service \
  -p 8086:8086 \
  -e TENCENT_SECRET_ID=your_secret_id \
  -e TENCENT_SECRET_KEY=your_secret_key \
  resume-centre-blockchain
```

### Kubernetes部署
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blockchain-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: blockchain-service
  template:
    metadata:
      labels:
        app: blockchain-service
    spec:
      containers:
      - name: blockchain-service
        image: resume-centre-blockchain:latest
        ports:
        - containerPort: 8086
        env:
        - name: TENCENT_SECRET_ID
          valueFrom:
            secretKeyRef:
              name: tencent-secrets
              key: secret-id
        - name: TENCENT_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: tencent-secrets
              key: secret-key
```

## 故障排除

### 常见问题

1. **腾讯云API连接失败**
   ```bash
   # 检查API密钥配置
   # 检查网络连接
   # 检查地域配置
   ```

2. **智能合约调用失败**
   ```bash
   # 检查合约ID配置
   # 检查函数名和参数
   # 查看腾讯云控制台日志
   ```

3. **数据库连接失败**
   ```bash
   # 检查数据库配置
   # 检查网络连接
   # 检查数据库权限
   ```

### 调试模式

设置环境变量启用调试模式：
```bash
export LOG_LEVEL=debug
export GIN_MODE=debug
```

## 性能优化

### 缓存策略
- Redis缓存热点数据
- 智能合约查询结果缓存
- 用户余额缓存

### 并发处理
- 异步区块链交易处理
- 连接池管理
- 批量操作优化

## 安全考虑

### API安全
- JWT认证
- 请求限流
- 参数验证

### 区块链安全
- 私钥安全存储
- 交易签名验证
- 权限控制

## 版本历史

### v2.0.0 (2024-12-19)
- ✅ 迁移到腾讯云区块链服务
- ✅ 添加积分交易功能
- ✅ 添加简历区块链存储
- ✅ 完善API接口
- ✅ 添加智能合约管理

### v1.0.0 (2024-12-01)
- ✅ 基础区块链服务
- ✅ 证书管理功能
- ✅ 钱包管理功能

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

如有问题，请提交 Issue 或联系开发团队。
