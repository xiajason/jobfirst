FROM golang:1.21-alpine AS builder

WORKDIR /app

# 复制go mod文件
COPY points/go.mod points/go.sum ./

# 复制shared目录
COPY shared ./shared

# 复制源代码
COPY points/ .

# 下载依赖
RUN go mod download

# 更新依赖
RUN go mod tidy

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o points-service .

# 运行阶段
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# 从构建阶段复制二进制文件
COPY --from=builder /app/points-service .
COPY --from=builder /app/config.yaml ./config/

# 暴露端口
EXPOSE 8083

# 运行应用
CMD ["./points-service"]
