# 腾讯云访问配置指南

## 🎯 快速配置腾讯云访问

### **第一步：获取腾讯云访问凭证**

1. **登录腾讯云控制台**
   - 访问: https://console.cloud.tencent.com/
   - 使用您的腾讯云账号登录

2. **创建访问密钥**
   - 进入 "访问管理" → "API密钥管理"
   - 点击 "新建密钥"
   - 保存 SecretId 和 SecretKey

3. **获取集群信息**
   - 进入 "容器服务" → "集群"
   - 记录集群ID (cls-xxxxx)
   - 记录集群访问地址

### **第二步：配置本地环境**

#### **安装腾讯云CLI**
```bash
# 安装腾讯云CLI
pip install tccli

# 配置凭证
tccli configure set secretId YOUR_SECRET_ID
tccli configure set secretKey YOUR_SECRET_KEY
tccli configure set region ap-guangzhou
```

#### **安装kubectl**
```bash
# 下载kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### **获取集群访问凭证**
```bash
# 获取kubeconfig
tccli tke DescribeClusterKubeconfig \
  --ClusterId cls-xxxxx \
  --IsExtranet true

# 保存到文件
echo "YOUR_KUBECONFIG_CONTENT" > ~/.kube/config
```

### **第三步：验证访问**

```bash
# 测试kubectl连接
kubectl cluster-info

# 查看节点
kubectl get nodes

# 查看命名空间
kubectl get namespaces
```

### **第四步：部署应用**

```bash
# 运行部署脚本
./scripts/deploy-tencent-cloud.sh staging ap-guangzhou jobfirst-cluster jobfirst-staging
```

## 🔍 查看部署状态

### **1. 腾讯云控制台查看**

#### **容器服务控制台**
- 访问: https://console.cloud.tencent.com/tke2
- 选择您的集群
- 查看 "工作负载" → "Deployment"
- 查看 "服务" → "Service"

#### **具体路径**
```
腾讯云控制台
├── 容器服务 TKE
│   ├── 集群管理
│   │   └── jobfirst-cluster
│   │       ├── 工作负载
│   │       │   ├── Deployment
│   │       │   │   ├── jobfirst-gateway
│   │       │   │   ├── jobfirst-frontend
│   │       │   │   └── mysql/redis
│   │       │   └── StatefulSet
│   │       │       └── mysql
│   │       ├── 服务
│   │       │   ├── jobfirst-gateway (LoadBalancer)
│   │       │   ├── jobfirst-frontend (LoadBalancer)
│   │       │   └── mysql/redis (ClusterIP)
│   │       └── 配置管理
│   │           ├── ConfigMap
│   │           └── Secret
│   └── 命名空间
│       └── jobfirst-staging
```

### **2. 命令行查看**

```bash
# 查看所有Pod
kubectl get pods -n jobfirst-staging

# 查看服务
kubectl get services -n jobfirst-staging

# 查看部署
kubectl get deployments -n jobfirst-staging

# 查看日志
kubectl logs -f deployment/jobfirst-gateway -n jobfirst-staging
```

### **3. 访问应用**

```bash
# 获取服务IP
kubectl get service jobfirst-gateway -n jobfirst-staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 访问API网关
curl http://GATEWAY_IP/health

# 访问前端
curl http://FRONTEND_IP/
```

## 📊 监控和日志

### **Prometheus监控**
- 访问: http://PROMETHEUS_IP:9090
- 查看应用指标

### **Grafana仪表板**
- 访问: http://GRAFANA_IP:3000
- 默认账号: admin/admin123

## 🔧 故障排除

### **常见问题**

1. **Pod启动失败**
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
   # 检查镜像仓库配置
   kubectl describe pod <pod-name> -n jobfirst-staging
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

如果遇到问题：

1. 查看腾讯云控制台日志
2. 检查kubectl连接状态
3. 验证集群和命名空间配置
4. 联系技术支持团队

---

**注意**: 请确保在生产环境部署前，充分测试所有配置和功能。
