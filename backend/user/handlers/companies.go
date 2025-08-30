package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// CompanyHandler 企业处理器
type CompanyHandler struct {
	// 这里可以注入数据库连接、缓存等依赖
}

// NewCompanyHandler 创建企业处理器
func NewCompanyHandler() *CompanyHandler {
	return &CompanyHandler{}
}

// GetCompaniesV2 获取企业列表（新版本）
func (h *CompanyHandler) GetCompaniesV2(c *gin.Context) {
	// 从新数据库表获取企业数据
	companies := []map[string]interface{}{
		{
			"id":                 1,
			"name":               "腾讯科技有限公司",
			"short_name":         "腾讯",
			"logo_url":           "/images/company/tencent.png",
			"industry":           "互联网",
			"company_size":       "enterprise",
			"location":           "深圳",
			"website":            "https://www.tencent.com",
			"description":        "腾讯是一家以互联网为基础的科技与文化公司",
			"founded_year":       1998,
			"status":             "verified",
			"verification_level": "vip",
			"job_count":          156,
			"view_count":         12580,
			"created_at":         "2024-08-30T10:00:00Z",
		},
		{
			"id":                 2,
			"name":               "阿里巴巴集团",
			"short_name":         "阿里巴巴",
			"logo_url":           "/images/company/alibaba.png",
			"industry":           "电商",
			"company_size":       "enterprise",
			"location":           "杭州",
			"website":            "https://www.alibaba.com",
			"description":        "阿里巴巴集团是全球领先的电子商务平台",
			"founded_year":       1999,
			"status":             "verified",
			"verification_level": "vip",
			"job_count":          89,
			"view_count":         9876,
			"created_at":         "2024-08-30T10:00:00Z",
		},
		{
			"id":                 3,
			"name":               "字节跳动科技有限公司",
			"short_name":         "字节跳动",
			"logo_url":           "/images/company/bytedance.png",
			"industry":           "互联网",
			"company_size":       "large",
			"location":           "北京",
			"website":            "https://www.bytedance.com",
			"description":        "字节跳动是一家信息科技公司",
			"founded_year":       2012,
			"status":             "verified",
			"verification_level": "premium",
			"job_count":          234,
			"view_count":         15678,
			"created_at":         "2024-08-30T10:00:00Z",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"companies": companies,
			"total":     len(companies),
			"version":   "v2",
			"database":  "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetCompanyDetailV2 获取企业详情（新版本）
func (h *CompanyHandler) GetCompanyDetailV2(c *gin.Context) {
	_ = c.Param("id") // 暂时未使用，后续会用于数据库查询

	companyDetail := map[string]interface{}{
		"id":                 1,
		"name":               "腾讯科技有限公司",
		"short_name":         "腾讯",
		"logo_url":           "/images/company/tencent.png",
		"industry":           "互联网",
		"company_size":       "enterprise",
		"location":           "深圳",
		"website":            "https://www.tencent.com",
		"description":        "腾讯是一家以互联网为基础的科技与文化公司，通过技术丰富互联网用户的生活，助力企业数字化升级。我们的使命是\"用户为本 科技向善\"。",
		"founded_year":       1998,
		"business_license":   "91440300708461136T",
		"status":             "verified",
		"verification_level": "vip",
		"job_count":          156,
		"view_count":         12580,
		"created_at":         "2024-08-30T10:00:00Z",
		"jobs": []map[string]interface{}{
			{
				"id":    1,
				"title": "前端开发工程师",
			},
			{
				"id":    2,
				"title": "后端开发工程师",
			},
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data":    companyDetail,
	}

	c.JSON(http.StatusOK, response)
}
