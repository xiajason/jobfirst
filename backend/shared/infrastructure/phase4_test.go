package infrastructure

import (
	"context"
	"fmt"
	"testing"
	"time"
)

func TestTracingService(t *testing.T) {
	// 创建追踪配置
	config := CreateDefaultTracingConfig()
	config.Enabled = true

	// 创建追踪服务
	tracing := NewSimpleTracing(config)

	// 测试开始跨度
	span := tracing.StartSpan("test-operation")
	if span == nil {
		t.Fatal("Expected span to be created")
	}

	// 测试设置属性
	span.SetAttributes(
		Field{Key: "test_key", Value: "test_value"},
		Field{Key: "test_count", Value: 42},
	)

	// 测试添加事件
	span.AddEvent("test_event",
		Field{Key: "event_type", Value: "test"},
	)

	// 测试设置状态
	span.SetStatus(0, "success")

	// 测试追踪ID
	traceID := span.GetTraceID()
	if traceID == "" {
		t.Error("Expected non-empty trace ID")
	}

	// 结束跨度
	span.End()

	// 测试关闭服务
	ctx := context.Background()
	err := tracing.Shutdown(ctx)
	if err != nil {
		t.Fatalf("Failed to shutdown tracing service: %v", err)
	}
}

func TestMessageQueue(t *testing.T) {
	// 创建消息队列配置
	config := CreateDefaultMessagingConfig()
	config.RedisAddr = "localhost:6379"

	// 创建消息队列
	queue, err := NewRedisStreamsQueue(config)
	if err != nil {
		t.Skipf("Skipping test - Redis not available: %v", err)
	}
	defer queue.Close()

	// 测试发布消息
	message := &Message{
		ID:    "test-message-1",
		Topic: "test-topic",
		Data: map[string]interface{}{
			"user_id": 123,
			"action":  "test_action",
		},
		Headers: map[string]string{
			"source": "test",
		},
		Timestamp: time.Now(),
	}

	err = queue.Publish(context.Background(), "test-topic", message)
	if err != nil {
		t.Fatalf("Failed to publish message: %v", err)
	}

	// 测试批量发布
	messages := []*Message{
		{
			ID:    "test-message-2",
			Topic: "test-topic",
			Data:  "test data 2",
		},
		{
			ID:    "test-message-3",
			Topic: "test-topic",
			Data:  "test data 3",
		},
	}

	err = queue.PublishBatch(context.Background(), "test-topic", messages)
	if err != nil {
		t.Fatalf("Failed to publish batch messages: %v", err)
	}

	// 测试订阅消息
	messageCount := 0
	handler := func(ctx context.Context, msg *Message) error {
		messageCount++
		return nil
	}

	err = queue.Subscribe(context.Background(), "test-topic", handler)
	if err != nil {
		t.Fatalf("Failed to subscribe to topic: %v", err)
	}

	// 等待消息处理
	time.Sleep(2 * time.Second)

	// 测试死信队列
	dlqMessages, err := queue.GetDeadLetterQueue(context.Background(), "test-topic")
	if err != nil {
		t.Fatalf("Failed to get dead letter queue: %v", err)
	}

	// 验证死信队列为空（因为消息处理成功）
	if len(dlqMessages) > 0 {
		t.Errorf("Expected empty dead letter queue, got %d messages", len(dlqMessages))
	}

	// 取消订阅
	err = queue.Unsubscribe(context.Background(), "test-topic")
	if err != nil {
		t.Fatalf("Failed to unsubscribe from topic: %v", err)
	}
}

func TestTracingMiddleware(t *testing.T) {
	// 创建追踪配置
	config := CreateDefaultTracingConfig()
	config.Enabled = true

	// 创建追踪服务
	tracing := NewSimpleTracing(config)

	// 设置全局追踪服务
	InitGlobalTracingService(tracing)

	// 创建追踪中间件
	middleware := TracingMiddleware("test-service")
	if middleware == nil {
		t.Fatal("Expected middleware to be created")
	}

	// 这里可以添加更多的中间件测试
	// 由于需要Gin上下文，这里只测试中间件创建
}

func TestMessageQueueWithRetry(t *testing.T) {
	// 创建消息队列配置
	config := CreateDefaultMessagingConfig()
	config.RedisAddr = "localhost:6379"
	config.MaxRetries = 2

	// 创建消息队列
	queue, err := NewRedisStreamsQueue(config)
	if err != nil {
		t.Skipf("Skipping test - Redis not available: %v", err)
	}
	defer queue.Close()

	// 测试重试机制
	retryCount := 0
	handler := func(ctx context.Context, msg *Message) error {
		retryCount++
		// 模拟失败，触发重试
		if retryCount < 3 {
			return fmt.Errorf("simulated error")
		}
		return nil
	}

	// 发布消息
	message := &Message{
		ID:    "retry-test-message",
		Topic: "retry-test-topic",
		Data:  "retry test data",
	}

	err = queue.Publish(context.Background(), "retry-test-topic", message)
	if err != nil {
		t.Fatalf("Failed to publish message: %v", err)
	}

	// 订阅并处理消息
	err = queue.Subscribe(context.Background(), "retry-test-topic", handler)
	if err != nil {
		t.Fatalf("Failed to subscribe to topic: %v", err)
	}

	// 等待消息处理和重试
	time.Sleep(5 * time.Second)

	// 验证重试次数
	if retryCount < 2 {
		t.Errorf("Expected at least 2 retries, got %d", retryCount)
	}

	// 取消订阅
	queue.Unsubscribe(context.Background(), "retry-test-topic")
}

func TestTracingWithContext(t *testing.T) {
	// 创建追踪配置
	config := CreateDefaultTracingConfig()
	config.Enabled = true

	// 创建追踪服务
	tracing := NewSimpleTracing(config)

	// 测试带上下文的跨度
	ctx := context.Background()
	span, newCtx := tracing.StartSpanWithContext(ctx, "test-context-operation")
	if span == nil {
		t.Fatal("Expected span to be created")
	}

	// 验证上下文是否被正确传递
	if newCtx == nil {
		t.Fatal("Expected new context to be created")
	}

	// 设置属性
	span.SetAttributes(
		Field{Key: "operation", Value: "test"},
		Field{Key: "value", Value: 100},
	)

	// 结束跨度
	span.End()

	// 关闭服务
	tracing.Shutdown(context.Background())
}

// Benchmark测试
func BenchmarkTracingService(b *testing.B) {
	config := CreateDefaultTracingConfig()
	config.Enabled = true

	tracing := NewSimpleTracing(config)
	defer tracing.Shutdown(context.Background())

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		span := tracing.StartSpan("benchmark-operation")
		span.SetAttributes(Field{Key: "benchmark", Value: "test"})
		span.End()
	}
}

func BenchmarkMessageQueue(b *testing.B) {
	config := CreateDefaultMessagingConfig()
	config.RedisAddr = "localhost:6379"

	queue, err := NewRedisStreamsQueue(config)
	if err != nil {
		b.Skipf("Skipping benchmark - Redis not available: %v", err)
	}
	defer queue.Close()

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		message := &Message{
			ID:    fmt.Sprintf("benchmark-message-%d", i),
			Topic: "benchmark-topic",
			Data:  fmt.Sprintf("benchmark data %d", i),
		}

		queue.Publish(context.Background(), "benchmark-topic", message)
	}
}
