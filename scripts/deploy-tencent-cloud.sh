#!/bin/bash

# JobFirst 腾讯云测试环境部署脚本
# 用于将项目部署到腾讯云测试环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 环境变量
ENVIRONMENT="${1:-staging}"
REGION="${2:-ap-guangzhou}"
CLUSTER_NAME="${3:-jobfirst-cluster}"
NAMESPACE="${4:-jobfirst-staging}"

# 腾讯云配置
TENCENT_CLOUD_CONFIG_FILE="configs/tencent-cloud.yaml"

log_info "开始部署到腾讯云测试环境"
log_info "环境: $ENVIRONMENT"
log_info "区域: $REGION"
log_info "集群: $CLUSTER_NAME"
log_info "命名空间: $NAMESPACE"

# 检查依赖工具
check_dependencies() {
    log_info "检查部署依赖工具..."
    
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl 未安装，请安装 kubectl"
        exit 1
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker 未安装，请安装 Docker"
        exit 1
    fi
    
    if ! command -v helm >/dev/null 2>&1; then
        log_warning "Helm 未安装，建议安装 Helm 用于包管理"
    fi
    
    log_success "所有依赖工具已安装"
}

# 创建腾讯云配置文件
create_tencent_cloud_config() {
    log_info "创建腾讯云配置文件..."
    
    mkdir -p configs
    
    cat > "$TENCENT_CLOUD_CONFIG_FILE" << EOF
# 腾讯云测试环境配置
apiVersion: v1
kind: Config
clusters:
- name: $CLUSTER_NAME
  cluster:
    server: https://your-cluster-endpoint.com
    certificate-authority-data: your-ca-data
contexts:
- name: $CLUSTER_NAME-context
  context:
    cluster: $CLUSTER_NAME
    namespace: $NAMESPACE
    user: $CLUSTER_NAME-user
current-context: $CLUSTER_NAME-context
users:
- name: $CLUSTER_NAME-user
  user:
    token: your-access-token
EOF
    
    log_success "腾讯云配置文件已创建: $TENCENT_CLOUD_CONFIG_FILE"
    log_warning "请更新配置文件中的实际连接信息"
}

# 构建Docker镜像
build_docker_images() {
    log_info "构建Docker镜像..."
    
    # 构建API网关镜像
    log_info "构建API网关镜像..."
    docker build -f backend/gateway/enhanced_Dockerfile -t jobfirst/gateway:latest backend/gateway/
    
    # 构建共享基础设施镜像
    log_info "构建共享基础设施镜像..."
    docker build -f backend/shared/infrastructure/Dockerfile -t jobfirst/shared-infrastructure:latest backend/shared/infrastructure/
    
    # 构建前端镜像
    log_info "构建前端镜像..."
    docker build -f frontend/web/Dockerfile -t jobfirst/frontend:latest frontend/web/
    
    log_success "所有Docker镜像构建完成"
}

# 推送镜像到腾讯云容器镜像服务
push_images_to_tencent() {
    log_info "推送镜像到腾讯云容器镜像服务..."
    
    # 配置腾讯云容器镜像服务
    REGISTRY_URL="ccr.ccs.tencentyun.com/your-namespace"
    
    # 标记镜像
    docker tag jobfirst/gateway:latest $REGISTRY_URL/jobfirst-gateway:latest
    docker tag jobfirst/shared-infrastructure:latest $REGISTRY_URL/jobfirst-shared-infrastructure:latest
    docker tag jobfirst/frontend:latest $REGISTRY_URL/jobfirst-frontend:latest
    
    # 推送镜像
    docker push $REGISTRY_URL/jobfirst-gateway:latest
    docker push $REGISTRY_URL/jobfirst-shared-infrastructure:latest
    docker push $REGISTRY_URL/jobfirst-frontend:latest
    
    log_success "镜像推送完成"
}

# 创建Kubernetes命名空间
create_namespace() {
    log_info "创建Kubernetes命名空间..."
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "命名空间 $NAMESPACE 已创建"
}

# 部署数据库服务
deploy_databases() {
    log_info "部署数据库服务..."
    
    # 创建数据库配置
    cat > k8s/databases.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: database-config
  namespace: $NAMESPACE
data:
  mysql.conf: |
    [mysqld]
    default-authentication-plugin=mysql_native_password
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: $NAMESPACE
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "jobfirst123"
        - name: MYSQL_DATABASE
          value: "jobfirst"
        - name: MYSQL_USER
          value: "jobfirst"
        - name: MYSQL_PASSWORD
          value: "jobfirst123"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
        - name: mysql-config
          mountPath: /etc/mysql/conf.d
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: $NAMESPACE
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: $NAMESPACE
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
    
    kubectl apply -f k8s/databases.yaml
    
    log_success "数据库服务部署完成"
}

# 部署应用服务
deploy_applications() {
    log_info "部署应用服务..."
    
    # 创建应用配置
    cat > k8s/applications.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jobfirst-gateway
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jobfirst-gateway
  template:
    metadata:
      labels:
        app: jobfirst-gateway
    spec:
      containers:
      - name: gateway
        image: ccr.ccs.tencentyun.com/your-namespace/jobfirst-gateway:latest
        ports:
        - containerPort: 8000
        env:
        - name: ENVIRONMENT
          value: "$ENVIRONMENT"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: jobfirst-gateway
  namespace: $NAMESPACE
spec:
  selector:
    app: jobfirst-gateway
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jobfirst-frontend
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jobfirst-frontend
  template:
    metadata:
      labels:
        app: jobfirst-frontend
    spec:
      containers:
      - name: frontend
        image: ccr.ccs.tencentyun.com/your-namespace/jobfirst-frontend:latest
        ports:
        - containerPort: 3000
        env:
        - name: NEXT_PUBLIC_API_URL
          value: "http://jobfirst-gateway.$NAMESPACE.svc.cluster.local"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: jobfirst-frontend
  namespace: $NAMESPACE
spec:
  selector:
    app: jobfirst-frontend
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: $NAMESPACE
type: Opaque
data:
  jwt-secret: $(echo -n "your-jwt-secret-key" | base64)
  db-password: $(echo -n "jobfirst123" | base64)
EOF
    
    kubectl apply -f k8s/applications.yaml
    
    log_success "应用服务部署完成"
}

# 部署监控服务
deploy_monitoring() {
    log_info "部署监控服务..."
    
    # 创建监控配置
    cat > k8s/monitoring.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: $NAMESPACE
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
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: $NAMESPACE
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: $NAMESPACE
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'jobfirst-gateway'
      static_configs:
      - targets: ['jobfirst-gateway:8000']
    - job_name: 'jobfirst-frontend'
      static_configs:
      - targets: ['jobfirst-frontend:3000']
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF
    
    kubectl apply -f k8s/monitoring.yaml
    
    log_success "监控服务部署完成"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    # 等待数据库服务
    kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=300s
    
    # 等待应用服务
    kubectl wait --for=condition=ready pod -l app=jobfirst-gateway -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=jobfirst-frontend -n $NAMESPACE --timeout=300s
    
    log_success "所有服务已就绪"
}

# 运行健康检查
run_health_checks() {
    log_info "运行健康检查..."
    
    # 获取服务IP
    GATEWAY_IP=$(kubectl get service jobfirst-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    FRONTEND_IP=$(kubectl get service jobfirst-frontend -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -n "$GATEWAY_IP" ]; then
        log_info "API网关地址: http://$GATEWAY_IP"
        curl -f http://$GATEWAY_IP/health || log_error "API网关健康检查失败"
    fi
    
    if [ -n "$FRONTEND_IP" ]; then
        log_info "前端地址: http://$FRONTEND_IP"
        curl -f http://$FRONTEND_IP || log_error "前端健康检查失败"
    fi
    
    log_success "健康检查完成"
}

# 显示部署信息
show_deployment_info() {
    log_info "=== 部署信息 ==="
    
    echo "环境: $ENVIRONMENT"
    echo "区域: $REGION"
    echo "集群: $CLUSTER_NAME"
    echo "命名空间: $NAMESPACE"
    echo ""
    
    echo "服务状态:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "服务地址:"
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo "访问地址:"
    GATEWAY_IP=$(kubectl get service jobfirst-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    FRONTEND_IP=$(kubectl get service jobfirst-frontend -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -n "$GATEWAY_IP" ]; then
        echo "API网关: http://$GATEWAY_IP"
    fi
    
    if [ -n "$FRONTEND_IP" ]; then
        echo "前端应用: http://$FRONTEND_IP"
    fi
}

# 主部署流程
main() {
    log_info "=== JobFirst 腾讯云测试环境部署 ==="
    log_info "开始时间: $(date)"
    
    # 检查依赖
    check_dependencies
    
    # 创建配置
    create_tencent_cloud_config
    
    # 构建镜像
    build_docker_images
    
    # 推送镜像
    push_images_to_tencent
    
    # 创建命名空间
    create_namespace
    
    # 部署数据库
    deploy_databases
    
    # 部署应用
    deploy_applications
    
    # 部署监控
    deploy_monitoring
    
    # 等待服务就绪
    wait_for_services
    
    # 健康检查
    run_health_checks
    
    # 显示部署信息
    show_deployment_info
    
    log_info "=== 部署完成 ==="
    log_info "结束时间: $(date)"
    
    log_success "JobFirst 已成功部署到腾讯云测试环境！"
}

# 脚本入口
main "$@"
