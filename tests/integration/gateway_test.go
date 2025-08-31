//go:build integration
// +build integration

package integration

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

// TestGatewayHealth 测试网关健康检查
func TestGatewayHealth(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	// 测试健康检查端点
	resp, err := client.Get("http://localhost:8000/health")
	if err != nil {
		t.Fatalf("健康检查请求失败: %v", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		t.Errorf("期望状态码200，实际得到: %d", resp.StatusCode)
	}
	
	// 检查响应内容
	var healthResponse map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&healthResponse); err != nil {
		t.Logf("响应不是JSON格式，这是正常的")
	} else {
		// 如果响应是JSON，检查状态字段
		if status, ok := healthResponse["status"].(string); ok {
			if status != "healthy" && status != "ok" && status != "up" {
				t.Errorf("健康状态异常: %s", status)
			}
		}
	}
}

// TestGatewayInfo 测试网关信息端点
func TestGatewayInfo(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	resp, err := client.Get("http://localhost:8000/info")
	if err != nil {
		t.Fatalf("信息端点请求失败: %v", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		t.Errorf("期望状态码200，实际得到: %d", resp.StatusCode)
	}
	
	// 检查响应内容
	var infoResponse map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&infoResponse); err != nil {
		t.Logf("响应不是JSON格式，这是正常的")
	} else {
		// 检查是否有版本信息
		if version, ok := infoResponse["version"].(string); ok {
			t.Logf("网关版本: %s", version)
		}
		
		// 检查功能列表
		if features, ok := infoResponse["features"].([]interface{}); ok {
			t.Logf("网关功能: %v", features)
		}
	}
}

// TestCORS 测试CORS配置
func TestCORS(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	// 创建预检请求
	req, err := http.NewRequest("OPTIONS", "http://localhost:8000/api/v1/user/profile", nil)
	if err != nil {
		t.Fatalf("创建预检请求失败: %v", err)
	}
	
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "POST")
	req.Header.Set("Access-Control-Request-Headers", "Content-Type,Authorization")
	
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("CORS预检请求失败: %v", err)
	}
	defer resp.Body.Close()
	
	// CORS预检请求应该返回204或200
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		t.Errorf("CORS预检请求期望状态码204或200，实际得到: %d", resp.StatusCode)
	}
	
	// 检查CORS响应头
	corsHeaders := []string{
		"Access-Control-Allow-Origin",
		"Access-Control-Allow-Methods",
		"Access-Control-Allow-Headers",
	}
	
	for _, header := range corsHeaders {
		if resp.Header.Get(header) == "" {
			t.Errorf("缺少CORS响应头: %s", header)
		}
	}
}

// TestAuthentication 测试认证机制
func TestAuthentication(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	testCases := []struct {
		name           string
		url            string
		headers        map[string]string
		expectedStatus int
	}{
		{
			name:           "无token访问受保护端点",
			url:            "http://localhost:8000/api/v1/user/profile",
			headers:        map[string]string{},
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name: "无效token访问",
			url:  "http://localhost:8000/api/v1/user/profile",
			headers: map[string]string{
				"Authorization": "Bearer invalid-token",
			},
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name: "格式错误token",
			url:  "http://localhost:8000/api/v1/user/profile",
			headers: map[string]string{
				"Authorization": "invalid-format",
			},
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name:           "访问公开端点",
			url:            "http://localhost:8000/health",
			headers:        map[string]string{},
			expectedStatus: http.StatusOK,
		},
	}
	
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req, err := http.NewRequest("GET", tc.url, nil)
			if err != nil {
				t.Fatalf("创建请求失败: %v", err)
			}
			
			// 添加请求头
			for key, value := range tc.headers {
				req.Header.Set(key, value)
			}
			
			resp, err := client.Do(req)
			if err != nil {
				t.Fatalf("请求失败: %v", err)
			}
			defer resp.Body.Close()
			
			if resp.StatusCode != tc.expectedStatus {
				t.Errorf("期望状态码%d，实际得到: %d", tc.expectedStatus, resp.StatusCode)
			}
		})
	}
}

// TestErrorHandling 测试错误处理
func TestErrorHandling(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	testCases := []struct {
		name           string
		method         string
		url            string
		expectedStatus int
	}{
		{
			name:           "404错误",
			method:         "GET",
			url:            "http://localhost:8000/nonexistent-endpoint",
			expectedStatus: http.StatusNotFound,
		},
		{
			name:           "405错误",
			method:         "POST",
			url:            "http://localhost:8000/health",
			expectedStatus: http.StatusMethodNotAllowed,
		},
	}
	
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req, err := http.NewRequest(tc.method, tc.url, nil)
			if err != nil {
				t.Fatalf("创建请求失败: %v", err)
			}
			
			resp, err := client.Do(req)
			if err != nil {
				t.Fatalf("请求失败: %v", err)
			}
			defer resp.Body.Close()
			
			if resp.StatusCode != tc.expectedStatus {
				t.Errorf("期望状态码%d，实际得到: %d", tc.expectedStatus, resp.StatusCode)
			}
		})
	}
}

// TestResponseTime 测试响应时间
func TestResponseTime(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	start := time.Now()
	resp, err := client.Get("http://localhost:8000/health")
	if err != nil {
		t.Fatalf("健康检查请求失败: %v", err)
	}
	defer resp.Body.Close()
	
	duration := time.Since(start)
	
	// 响应时间应该在1秒内
	if duration > time.Second {
		t.Errorf("响应时间过长: %v", duration)
	}
	
	t.Logf("响应时间: %v", duration)
}

// TestAPIVersioning 测试API版本控制
func TestAPIVersioning(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	// 测试不同版本的API端点
	versions := []string{"v1", "v2"}
	
	for _, version := range versions {
		t.Run(fmt.Sprintf("API版本%s", version), func(t *testing.T) {
			url := fmt.Sprintf("http://localhost:8000/api/%s/user/profile", version)
			
			req, err := http.NewRequest("GET", url, nil)
			if err != nil {
				t.Fatalf("创建请求失败: %v", err)
			}
			
			resp, err := client.Do(req)
			if err != nil {
				t.Fatalf("请求失败: %v", err)
			}
			defer resp.Body.Close()
			
			// 应该返回401（需要认证）而不是404（端点不存在）
			if resp.StatusCode == http.StatusNotFound {
				t.Errorf("API版本%s端点不存在", version)
			} else if resp.StatusCode != http.StatusUnauthorized {
				t.Errorf("期望状态码401，实际得到: %d", resp.StatusCode)
			}
		})
	}
}

// TestLoadBalancing 测试负载均衡（如果有多个实例）
func TestLoadBalancing(t *testing.T) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	// 发送多个请求，检查是否被路由到不同实例
	responses := make(map[string]int)
	
	for i := 0; i < 10; i++ {
		resp, err := client.Get("http://localhost:8000/health")
		if err != nil {
			t.Fatalf("请求失败: %v", err)
		}
		defer resp.Body.Close()
		
		// 检查是否有服务器标识头
		server := resp.Header.Get("Server")
		if server != "" {
			responses[server]++
		}
		
		time.Sleep(100 * time.Millisecond)
	}
	
	// 如果有多个服务器标识，说明负载均衡在工作
	if len(responses) > 1 {
		t.Logf("检测到负载均衡，服务器分布: %v", responses)
	} else {
		t.Logf("单实例或负载均衡未启用")
	}
}
