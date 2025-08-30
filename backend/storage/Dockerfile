FROM golang:1.21-alpine AS builder

WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    gcc \
    musl-dev \
    pkgconfig \
    cairo-dev \
    jpeg-dev \
    libpng-dev \
    giflib-dev \
    libwebp-dev

# 复制go mod文件
COPY storage/go.mod storage/go.sum ./

# 复制shared目录
COPY shared ./shared

# 下载依赖
RUN go mod download

# 复制源代码
COPY storage/ .

# 更新依赖
RUN go mod tidy

# 构建应用
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o storage-service .

# 运行阶段
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    cairo \
    jpeg \
    libpng \
    giflib \
    libwebp \
    imagemagick

WORKDIR /root/

# 从构建阶段复制二进制文件
COPY --from=builder /app/storage-service .
COPY --from=builder /app/config.yaml ./config/

# 创建存储目录
RUN mkdir -p /data/files /tmp/uploads /tmp/processed

# 设置权限
RUN chmod 755 /data/files /tmp/uploads /tmp/processed

# 暴露端口
EXPOSE 8088

# 运行应用
CMD ["./storage-service"]
