package utils

import (
	"resume-centre/api/constants"
	"resume-centre/api/types"

	"github.com/gin-gonic/gin"
)

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(constants.StatusOK, types.NewSuccessResponse(data))
}

// Created 创建成功响应
func Created(c *gin.Context, data interface{}) {
	c.JSON(constants.StatusCreated, types.NewSuccessResponse(data))
}

// NoContent 无内容响应
func NoContent(c *gin.Context) {
	c.Status(constants.StatusNoContent)
}

// Error 错误响应
func Error(c *gin.Context, code int, message string) {
	if message == "" {
		message = constants.GetMessage(code)
	}
	c.JSON(code, types.NewErrorResponse(code, message))
}

// BadRequest 参数错误响应
func BadRequest(c *gin.Context, message string) {
	Error(c, constants.StatusBadRequest, message)
}

// Unauthorized 未授权响应
func Unauthorized(c *gin.Context, message string) {
	Error(c, constants.StatusUnauthorized, message)
}

// Forbidden 禁止访问响应
func Forbidden(c *gin.Context, message string) {
	Error(c, constants.StatusForbidden, message)
}

// NotFound 资源不存在响应
func NotFound(c *gin.Context, message string) {
	Error(c, constants.StatusNotFound, message)
}

// Conflict 资源冲突响应
func Conflict(c *gin.Context, message string) {
	Error(c, constants.StatusConflict, message)
}

// InternalError 内部错误响应
func InternalError(c *gin.Context, message string) {
	Error(c, constants.StatusInternalServerError, message)
}

// ServiceUnavailable 服务不可用响应
func ServiceUnavailable(c *gin.Context, message string) {
	Error(c, constants.StatusServiceUnavailable, message)
}

// TooManyRequests 请求频率超限响应
func TooManyRequests(c *gin.Context, message string) {
	Error(c, constants.StatusTooManyRequests, message)
}

// BusinessError 业务错误响应
func BusinessError(c *gin.Context, code int, message string) {
	if message == "" {
		message = constants.GetMessage(code)
	}
	c.JSON(constants.StatusOK, types.NewErrorResponse(code, message))
}

// PageSuccess 分页成功响应
func PageSuccess(c *gin.Context, total int64, page, pageSize int, list interface{}) {
	pageResponse := types.NewPageResponse(total, page, pageSize, list)
	c.JSON(constants.StatusOK, types.NewSuccessResponse(pageResponse))
}

// SetTraceID 设置追踪ID
func SetTraceID(c *gin.Context, traceID string) {
	c.Set("trace_id", traceID)
}

// GetTraceID 获取追踪ID
func GetTraceID(c *gin.Context) string {
	if traceID, exists := c.Get("trace_id"); exists {
		if id, ok := traceID.(string); ok {
			return id
		}
	}
	return ""
}

// SetUserContext 设置用户上下文
func SetUserContext(c *gin.Context, userContext *types.UserContext) {
	c.Set("user_context", userContext)
}

// GetUserContext 获取用户上下文
func GetUserContext(c *gin.Context) *types.UserContext {
	if userContext, exists := c.Get("user_context"); exists {
		if ctx, ok := userContext.(*types.UserContext); ok {
			return ctx
		}
	}
	return nil
}

// GetUserID 获取用户ID
func GetUserID(c *gin.Context) string {
	userContext := GetUserContext(c)
	if userContext != nil {
		return userContext.UserID
	}
	return ""
}
