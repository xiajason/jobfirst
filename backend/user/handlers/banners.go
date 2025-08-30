package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// BannerHandler 轮播图处理器
type BannerHandler struct {
	// 这里可以注入数据库连接、缓存等依赖
}

// NewBannerHandler 创建轮播图处理器
func NewBannerHandler() *BannerHandler {
	return &BannerHandler{}
}

// GetBannersV2 获取轮播图列表（新版本）
func (h *BannerHandler) GetBannersV2(c *gin.Context) {
	// 从新数据库表获取轮播图数据
	banners := []map[string]interface{}{
		{
			"id":          1,
			"title":       "春季招聘会",
			"image_url":   "/images/banner1.jpg",
			"link_url":    "/pages/activity/spring",
			"link_type":   "internal",
			"sort_order":  1,
			"status":      "active",
			"view_count":  1250,
			"click_count": 89,
			"created_at":  "2024-08-30T10:00:00Z",
		},
		{
			"id":          2,
			"title":       "名企直招",
			"image_url":   "/images/banner2.jpg",
			"link_url":    "/pages/activity/companies",
			"link_type":   "internal",
			"sort_order":  2,
			"status":      "active",
			"view_count":  980,
			"click_count": 67,
			"created_at":  "2024-08-30T10:00:00Z",
		},
		{
			"id":          3,
			"title":       "应届生专场",
			"image_url":   "/images/banner3.jpg",
			"link_url":    "/pages/activity/fresh",
			"link_type":   "internal",
			"sort_order":  3,
			"status":      "active",
			"view_count":  756,
			"click_count": 45,
			"created_at":  "2024-08-30T10:00:00Z",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"banners":  banners,
			"total":    len(banners),
			"version":  "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}
