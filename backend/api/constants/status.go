package constants

// HTTP状态码
const (
	// 成功状态码
	StatusOK        = 200
	StatusCreated   = 201
	StatusAccepted  = 202
	StatusNoContent = 204

	// 客户端错误状态码
	StatusBadRequest          = 400
	StatusUnauthorized        = 401
	StatusForbidden           = 403
	StatusNotFound            = 404
	StatusMethodNotAllowed    = 405
	StatusConflict            = 409
	StatusUnprocessableEntity = 422
	StatusTooManyRequests     = 429

	// 服务器错误状态码
	StatusInternalServerError = 500
	StatusNotImplemented      = 501
	StatusBadGateway          = 502
	StatusServiceUnavailable  = 503
	StatusGatewayTimeout      = 504
)

// 业务状态码
const (
	// 成功
	CodeSuccess = 0

	// 客户端错误 (1000-1999)
	CodeInvalidParameter   = 1000 // 参数无效
	CodeMissingParameter   = 1001 // 缺少参数
	CodeInvalidFormat      = 1002 // 格式无效
	CodeUnauthorized       = 1003 // 未授权
	CodeForbidden          = 1004 // 禁止访问
	CodeResourceNotFound   = 1005 // 资源不存在
	CodeResourceExists     = 1006 // 资源已存在
	CodeInvalidCredentials = 1007 // 凭据无效
	CodeTokenExpired       = 1008 // 令牌过期
	CodeTokenInvalid       = 1009 // 令牌无效
	CodePermissionDenied   = 1010 // 权限不足
	CodeRateLimitExceeded  = 1011 // 请求频率超限
	CodeValidationFailed   = 1012 // 验证失败

	// 业务错误 (2000-2999)
	CodeUserNotFound       = 2000 // 用户不存在
	CodeUserExists         = 2001 // 用户已存在
	CodeResumeNotFound     = 2002 // 简历不存在
	CodeResumeExists       = 2003 // 简历已存在
	CodeTemplateNotFound   = 2004 // 模板不存在
	CodePointsInsufficient = 2005 // 积分不足
	CodeFileUploadFailed   = 2006 // 文件上传失败
	CodeFileNotFound       = 2007 // 文件不存在
	CodeOperationFailed    = 2008 // 操作失败
	CodeStatusInvalid      = 2009 // 状态无效

	// 系统错误 (3000-3999)
	CodeDatabaseError      = 3000 // 数据库错误
	CodeCacheError         = 3001 // 缓存错误
	CodeNetworkError       = 3002 // 网络错误
	CodeServiceUnavailable = 3003 // 服务不可用
	CodeInternalError      = 3004 // 内部错误
	CodeConfigError        = 3005 // 配置错误
	CodeTimeout            = 3006 // 超时
	CodeUnknownError       = 3999 // 未知错误
)

// 状态消息
var StatusMessages = map[int]string{
	// HTTP状态码消息
	StatusOK:                  "请求成功",
	StatusCreated:             "创建成功",
	StatusAccepted:            "请求已接受",
	StatusNoContent:           "无内容",
	StatusBadRequest:          "请求参数错误",
	StatusUnauthorized:        "未授权",
	StatusForbidden:           "禁止访问",
	StatusNotFound:            "资源不存在",
	StatusMethodNotAllowed:    "方法不允许",
	StatusConflict:            "资源冲突",
	StatusUnprocessableEntity: "请求无法处理",
	StatusTooManyRequests:     "请求过于频繁",
	StatusInternalServerError: "服务器内部错误",
	StatusNotImplemented:      "功能未实现",
	StatusBadGateway:          "网关错误",
	StatusServiceUnavailable:  "服务不可用",
	StatusGatewayTimeout:      "网关超时",

	// 业务状态码消息
	CodeSuccess:            "操作成功",
	CodeInvalidParameter:   "参数无效",
	CodeMissingParameter:   "缺少参数",
	CodeInvalidFormat:      "格式无效",
	CodeUnauthorized:       "未授权",
	CodeForbidden:          "禁止访问",
	CodeResourceNotFound:   "资源不存在",
	CodeResourceExists:     "资源已存在",
	CodeInvalidCredentials: "凭据无效",
	CodeTokenExpired:       "令牌已过期",
	CodeTokenInvalid:       "令牌无效",
	CodePermissionDenied:   "权限不足",
	CodeRateLimitExceeded:  "请求频率超限",
	CodeValidationFailed:   "验证失败",
	CodeUserNotFound:       "用户不存在",
	CodeUserExists:         "用户已存在",
	CodeResumeNotFound:     "简历不存在",
	CodeResumeExists:       "简历已存在",
	CodeTemplateNotFound:   "模板不存在",
	CodePointsInsufficient: "积分不足",
	CodeFileUploadFailed:   "文件上传失败",
	CodeFileNotFound:       "文件不存在",
	CodeOperationFailed:    "操作失败",
	CodeStatusInvalid:      "状态无效",
	CodeDatabaseError:      "数据库错误",
	CodeCacheError:         "缓存错误",
	CodeNetworkError:       "网络错误",
	CodeServiceUnavailable: "服务不可用",
	CodeInternalError:      "内部错误",
	CodeConfigError:        "配置错误",
	CodeTimeout:            "请求超时",
	CodeUnknownError:       "未知错误",
}

// GetMessage 获取状态消息
func GetMessage(code int) string {
	if message, exists := StatusMessages[code]; exists {
		return message
	}
	return StatusMessages[CodeUnknownError]
}
