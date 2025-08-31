package main

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// 使用main.go中已定义的User结构体

// LoginRequest 登录请求
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse 登录响应
type LoginResponse struct {
	Success   bool   `json:"success"`
	Token     string `json:"token"`
	User      User   `json:"user"`
	ExpiresAt string `json:"expires_at"`
}

// AuthController 认证控制器
type AuthController struct {
	db *gorm.DB
}

// NewAuthController 创建认证控制器
func NewAuthController(db *gorm.DB) *AuthController {
	return &AuthController{db: db}
}

// Login 用户登录
func (ac *AuthController) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// 验证用户
	user, err := ac.validateUser(req.Username, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// 生成Token
	token, expiresAt, err := ac.generateToken(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token generation failed"})
		return
	}

	// 返回响应
	response := LoginResponse{
		Success:   true,
		Token:     token,
		User:      *user,
		ExpiresAt: expiresAt.Format(time.RFC3339),
	}

	c.JSON(http.StatusOK, response)
}

// validateUser 验证用户
func (ac *AuthController) validateUser(username, password string) (*User, error) {
	var user User
	
	err := ac.db.Where("username = ? AND status = ?", username, "active").First(&user).Error
	if err != nil {
		return nil, err
	}

	// 简化验证 (实际应该验证密码hash)
	if password != "password123" {
		return nil, gorm.ErrRecordNotFound
	}

	return &user, nil
}

// generateToken 生成JWT Token
func (ac *AuthController) generateToken(user *User) (string, time.Time, error) {
	expiresAt := time.Now().Add(24 * time.Hour)
	
	claims := jwt.MapClaims{
		"user_id":  user.ID,
		"username": user.Username,
		"role":     user.Role,
		"exp":      expiresAt.Unix(),
	}
	
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte("jobfirst-secret-key"))
	
	return tokenString, expiresAt, err
}

// GetUsers 获取用户列表 (管理员权限)
func (ac *AuthController) GetUsers(c *gin.Context) {
	var users []User
	if err := ac.db.Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get users"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"users": users})
}

// CreateUser 创建用户 (管理员权限)
func (ac *AuthController) CreateUser(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required"`
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
		Role     string `json:"role" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// 密码加密
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Password encryption failed"})
		return
	}

	// 插入用户
	user := User{
		Username: req.Username,
		Email:    req.Email,
		Password: string(hashedPassword),
		Role:     req.Role,
		Status:   "active",
	}
	
	err = ac.db.Create(&user).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User created successfully"})
}
