# JobFirst 腾讯云测试环境配置指南

## 🎯 概述

本文档介绍如何将JobFirst项目部署到腾讯云测试环境，包括容器服务、数据库、监控等组件的配置。

## 🏗️ 架构设计

### **测试环境架构**

```
腾讯云容器服务 (TKE)
├── 命名空间: jobfirst-staging
├── 数据库服务
│   ├── MySQL 8.0 (StatefulSet)
│   └── Redis 7 (Deployment)
├── 应用服务
│   ├── API网关 (Deployment + LoadBalancer)
│   └── 前端应用 (Deployment + LoadBalancer)
└── 监控服务
    ├── Prometheus (Deployment)
    └── Grafana (Deployment)
```

### **网络架构**

- **内网通信**: 服务间通过Kubernetes Service通信
- **外网访问**: 通过LoadBalancer暴露服务
- **数据库**: 仅内网访问，确保安全性

## 🚀 部署步骤

### **1. 准备工作**

#### **1.1 安装必要工具**

```bash
# 安装 kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# 安装 Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 安装 Helm (可选)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### **1.2 配置腾讯云访问**

```bash
# 下载腾讯云 CLI
pip install tccli

# 配置腾讯云凭证
tccli configure set secretId YOUR_SECRET_ID
tccli configure set secretKey YOUR_SECRET_KEY
tccli configure set region ap-guangzhou
```

### **2. 创建腾讯云资源**

#### **2.1 创建容器集群**

```bash
# 创建 TKE 集群
tccli tke CreateCluster \
  --ClusterName jobfirst-cluster \
  --ClusterDesc "JobFirst测试环境集群" \
  --ClusterType ManagedCluster \
  --VpcId vpc-xxxxx \
  --ClusterCIDR 10.0.0.0/16 \
  --ClusterMaxPodNum 32 \
  --ClusterMaxServiceNum 32 \
  --ClusterIPServiceCIDR 172.16.0.0/16 \
  --ClusterVersion 1.24.4
```

#### **2.2 创建容器镜像仓库**

```bash
# 创建容器镜像仓库
tccli tcr CreateInstance \
  --RegistryName jobfirst-registry \
  --RegistryType Standard \
  --TagSpecification ResourceType=registry,Tags.0.Key=project,Tags.0.Value=jobfirst

# 创建命名空间
tccli tcr CreateNamespace \
  --RegistryId tcr-xxxxx \
  --Name jobfirst
```

#### **2.3 配置 kubectl**

```bash
# 获取集群访问凭证
tccli tke DescribeClusterKubeconfig \
  --ClusterId cls-xxxxx \
  --IsExtranet true

# 配置 kubectl
kubectl config set-cluster jobfirst-cluster \
  --server=https://your-cluster-endpoint.com \
  --certificate-authority=/path/to/ca.crt

kubectl config set-credentials jobfirst-user \
  --token=your-access-token

kubectl config set-context jobfirst-context \
  --cluster=jobfirst-cluster \
  --user=jobfirst-user \
  --namespace=jobfirst-staging

kubectl config use-context jobfirst-context
```

### **3. 部署应用**

#### **3.1 构建和推送镜像**

```bash
# 登录腾讯云容器镜像服务
docker login ccr.ccs.tencentyun.com

# 构建镜像
docker build -f backend/gateway/enhanced_Dockerfile -t ccr.ccs.tencentyun.com/jobfirst/jobfirst-gateway:latest backend/gateway/
docker build -f frontend/web/Dockerfile -t ccr.ccs.tencentyun.com/jobfirst/jobfirst-frontend:latest frontend/web/

# 推送镜像
docker push ccr.ccs.tencentyun.com/jobfirst/jobfirst-gateway:latest
docker push ccr.ccs.tencentyun.com/jobfirst/jobfirst-frontend:latest
```

#### **3.2 部署应用**

```bash
# 创建命名空间
kubectl create namespace jobfirst-staging

# 部署应用
kubectl apply -f k8s/databases.yaml
kubectl apply -f k8s/applications.yaml
kubectl apply -f k8s/monitoring.yaml
```

### **4. 配置监控**

#### **4.1 部署 Prometheus**

```yaml
# k8s/prometheus.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: jobfirst-staging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: prometheus-config
          mountPath: /etc/prometheus
        - name: prometheus-data
          mountPath: /prometheus
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
      - name: prometheus-data
        persistentVolumeClaim:
          claimName: prometheus-pvc
```

#### **4.2 部署 Grafana**

```yaml
# k8s/grafana.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: jobfirst-staging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        volumeMounts:
        - name: grafana-data
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-data
        persistentVolumeClaim:
          claimName: grafana-pvc
```

## 🔧 配置管理

### **环境变量配置**

```yaml
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: jobfirst-staging
data:
  ENVIRONMENT: "staging"
  API_BASE_URL: "http://jobfirst-gateway.jobfirst-staging.svc.cluster.local"
  DATABASE_URL: "mysql://jobfirst:jobfirst123@mysql:3306/jobfirst"
  REDIS_URL: "redis://redis:6379"
```

### **密钥管理**

```yaml
# k8s/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: jobfirst-staging
type: Opaque
data:
  jwt-secret: <base64-encoded-jwt-secret>
  db-password: <base64-encoded-db-password>
  redis-password: <base64-encoded-redis-password>
```

## 📊 监控和日志

### **Prometheus 配置**

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
- job_name: 'jobfirst-gateway'
  static_configs:
  - targets: ['jobfirst-gateway:8000']
  metrics_path: '/metrics'

- job_name: 'jobfirst-frontend'
  static_configs:
  - targets: ['jobfirst-frontend:3000']
  metrics_path: '/metrics'

- job_name: 'mysql'
  static_configs:
  - targets: ['mysql:3306']

- job_name: 'redis'
  static_configs:
  - targets: ['redis:6379']
```

### **Grafana 仪表板**

导入以下仪表板配置：

1. **应用性能监控**
   - API响应时间
   - 请求成功率
   - 错误率统计

2. **系统资源监控**
   - CPU使用率
   - 内存使用率
   - 磁盘使用率

3. **数据库监控**
   - 连接数
   - 查询性能
   - 慢查询统计

## 🔒 安全配置

### **网络安全**

```yaml
# k8s/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: jobfirst-network-policy
  namespace: jobfirst-staging
spec:
  podSelector:
    matchLabels:
      app: jobfirst-gateway
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: jobfirst-staging
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: jobfirst-staging
    ports:
    - protocol: TCP
      port: 3306
    - protocol: TCP
      port: 6379
```

### **RBAC 配置**

```yaml
# k8s/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: jobfirst-staging
  name: jobfirst-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jobfirst-role-binding
  namespace: jobfirst-staging
subjects:
- kind: ServiceAccount
  name: jobfirst-service-account
  namespace: jobfirst-staging
roleRef:
  kind: Role
  name: jobfirst-role
  apiGroup: rbac.authorization.k8s.io
```

## 🚀 自动化部署

### **使用部署脚本**

```bash
# 运行部署脚本
./scripts/deploy-tencent-cloud.sh staging ap-guangzhou jobfirst-cluster jobfirst-staging
```

### **CI/CD 集成**

在 `.github/workflows/ci-cd-pipeline.yml` 中添加腾讯云部署步骤：

```yaml
- name: Deploy to Tencent Cloud
  if: github.ref == 'refs/heads/develop'
  run: |
    # 配置腾讯云访问
    echo "${{ secrets.TENCENT_CLOUD_CONFIG }}" > kubeconfig.yaml
    export KUBECONFIG=kubeconfig.yaml
    
    # 部署应用
    ./scripts/deploy-tencent-cloud.sh staging
```

## 📋 检查清单

### **部署前检查**

- [ ] 腾讯云账号已配置
- [ ] 容器集群已创建
- [ ] 镜像仓库已配置
- [ ] kubectl 已配置
- [ ] Docker 镜像已构建
- [ ] 配置文件已更新

### **部署后检查**

- [ ] 所有 Pod 状态为 Running
- [ ] 服务可以正常访问
- [ ] 数据库连接正常
- [ ] 监控数据正常
- [ ] 日志输出正常
- [ ] 健康检查通过

## 🔧 故障排除

### **常见问题**

1. **Pod 启动失败**
   ```bash
   kubectl describe pod <pod-name> -n jobfirst-staging
   kubectl logs <pod-name> -n jobfirst-staging
   ```

2. **服务无法访问**
   ```bash
   kubectl get services -n jobfirst-staging
   kubectl describe service <service-name> -n jobfirst-staging
   ```

3. **镜像拉取失败**
   ```bash
   kubectl describe pod <pod-name> -n jobfirst-staging
   # 检查镜像仓库配置和权限
   ```

### **日志查看**

```bash
# 查看应用日志
kubectl logs -f deployment/jobfirst-gateway -n jobfirst-staging

# 查看数据库日志
kubectl logs -f statefulset/mysql -n jobfirst-staging

# 查看监控日志
kubectl logs -f deployment/prometheus -n jobfirst-staging
```

## 📞 支持

如果遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查腾讯云控制台日志
3. 联系技术支持团队

---

**注意**: 请确保在生产环境部署前，充分测试所有配置和功能。
