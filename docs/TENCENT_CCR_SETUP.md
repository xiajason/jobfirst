# 腾讯云容器镜像服务配置指南

## 概述

为了解决CI/CD流水线中Docker镜像拉取失败的问题，我们将使用腾讯云容器镜像服务（Tencent Cloud Container Registry, TCR）来替代Docker Hub。

## 优势

1. **网络稳定性** - 腾讯云内网访问，避免网络连接问题
2. **安全性** - 私有镜像仓库，更好的安全控制
3. **性能** - 国内访问速度更快
4. **成本** - 腾讯云用户可能有免费额度

## 配置步骤

### 1. 创建腾讯云容器镜像服务实例

1. 登录腾讯云控制台：https://console.cloud.tencent.com/
2. 搜索"容器镜像服务"或直接访问：https://console.cloud.tencent.com/tcr
3. 创建新的容器镜像服务实例（如果还没有）
4. 选择合适的地域和规格

### 2. 创建命名空间

1. 在容器镜像服务控制台中，进入"命名空间"
2. 创建名为 `jobfirst` 的命名空间
3. 设置为私有命名空间

### 3. 创建镜像仓库

在 `jobfirst` 命名空间下创建以下镜像仓库：

- `jobfirst-gateway` - API网关服务
- `jobfirst-shared-infra` - 共享基础设施服务  
- `jobfirst-user` - 用户服务

### 4. 获取访问凭证

1. 在容器镜像服务控制台中，进入"访问凭证"
2. 创建新的访问凭证
3. 记录以下信息：
   - 用户名（通常是邮箱）
   - 密码（临时密码）

### 5. 配置GitHub Secrets

在GitHub仓库中设置以下Secrets：

1. 进入仓库 Settings > Secrets and variables > Actions
2. 点击 "New repository secret"
3. 添加以下Secrets：

```
TENCENT_CCR_USERNAME: 腾讯云容器镜像服务用户名
TENCENT_CCR_PASSWORD: 腾讯云容器镜像服务密码
```

### 6. 验证配置

1. 推送代码到 `develop` 分支
2. 检查GitHub Actions流水线
3. 确认镜像成功推送到腾讯云容器镜像服务
4. 确认服务器成功拉取镜像

## 镜像地址格式

修改后的镜像地址格式：
```
ccr.ccs.tencentyun.com/jobfirst/jobfirst-gateway:staging-{commit-sha}
ccr.ccs.tencentyun.com/jobfirst/jobfirst-shared-infra:staging-{commit-sha}
ccr.ccs.tencentyun.com/jobfirst/jobfirst-user:staging-{commit-sha}
```

## 故障排除

### 常见问题

1. **认证失败**
   - 检查用户名和密码是否正确
   - 确认访问凭证是否过期

2. **推送失败**
   - 检查命名空间和仓库是否存在
   - 确认有推送权限

3. **拉取失败**
   - 检查服务器网络连接
   - 确认镜像标签正确

### 调试命令

```bash
# 测试登录
docker login ccr.ccs.tencentyun.com

# 测试拉取镜像
docker pull ccr.ccs.tencentyun.com/jobfirst/jobfirst-gateway:staging-{commit-sha}

# 查看镜像列表
docker images | grep ccr.ccs.tencentyun.com
```

## 成本说明

- 腾讯云容器镜像服务通常有免费额度
- 超出免费额度后按存储量和流量计费
- 建议定期清理不需要的镜像以控制成本

## 安全建议

1. 定期轮换访问凭证
2. 使用最小权限原则
3. 监控镜像仓库的访问日志
4. 定期扫描镜像安全漏洞
