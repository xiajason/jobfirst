FROM golang:1.21-alpine AS builder

WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    tesseract \
    tesseract-data-eng \
    tesseract-data-chi-sim \
    tesseract-data-jpn \
    tesseract-data-kor \
    poppler-utils \
    libreoffice \
    pandoc

# 复制go mod文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o document-service .

# 运行阶段
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tesseract \
    tesseract-data-eng \
    tesseract-data-chi-sim \
    tesseract-data-jpn \
    tesseract-data-kor \
    poppler-utils \
    libreoffice \
    pandoc

WORKDIR /root/

# 从构建阶段复制二进制文件
COPY --from=builder /app/document-service .
COPY --from=builder /app/config.yaml ./config/

# 创建临时目录
RUN mkdir -p /tmp/uploads /tmp/processed

# 暴露端口
EXPOSE 8087

# 运行应用
CMD ["./document-service"]
