package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/hashicorp/consul/api"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var (
	consulClient *api.Client
	logger       *logrus.Logger
	redisClient  *redis.Client
	db           *gorm.DB
)

func main() {
	// 初始化日志
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)

	// 加载配置
	if err := loadConfig(); err != nil {
		logger.Fatalf("Failed to load config: %v", err)
	}

	// 初始化数据库
	if err := initDatabase(); err != nil {
		logger.Fatalf("Failed to init database: %v", err)
	}

	// 初始化Consul客户端
	if err := initConsulClient(); err != nil {
		logger.Fatalf("Failed to init consul client: %v", err)
	}

	// 初始化Redis客户端
	if err := initRedisClient(); err != nil {
		logger.Fatalf("Failed to init redis client: %v", err)
	}

	// 注册服务到Consul
	if err := registerService(); err != nil {
		logger.Fatalf("Failed to register service: %v", err)
	}

	// 启动HTTP服务器
	router := setupRouter()
	port := viper.GetString("server.port")
	if port == "" {
		port = "8086"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// 优雅关闭
	go func() {
		logger.Infof("Starting blockchain service on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutting down server...")

	// 注销服务
	if err := deregisterService(); err != nil {
		logger.Errorf("Failed to deregister service: %v", err)
	}

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatalf("Server forced to shutdown: %v", err)
	}

	logger.Info("Server exited")
}

func loadConfig() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	// 设置默认值
	viper.SetDefault("server.port", "9009")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", "8200")
	viper.SetDefault("database.name", "jobfirst")
	viper.SetDefault("database.user", "jobfirst")
	viper.SetDefault("database.password", "jobfirst123")
	viper.SetDefault("consul.address", "localhost:8202")
	viper.SetDefault("redis.address", "localhost:8201")
	viper.SetDefault("redis.password", "")
	viper.SetDefault("redis.db", 0)

	// 腾讯云区块链配置默认值
	viper.SetDefault("tencent.secret_id", "")
	viper.SetDefault("tencent.secret_key", "")
	viper.SetDefault("tencent.region", "ap-guangzhou")
	viper.SetDefault("tencent.blockchain.cluster_id", "")
	viper.SetDefault("tencent.blockchain.channel_id", "")
	viper.SetDefault("tencent.blockchain.chaincode_id", "")

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return err
		}
	}

	// 从环境变量读取配置
	viper.AutomaticEnv()

	return nil
}

func initDatabase() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		viper.GetString("database.user"),
		viper.GetString("database.password"),
		viper.GetString("database.host"),
		viper.GetString("database.port"),
		viper.GetString("database.name"),
	)

	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}

	// 自动迁移数据库表
	if err := db.AutoMigrate(
		&BlockchainCertificate{},
		&BlockchainTransaction{},
		&Wallet{},
		&SmartContract{},
		&BlockchainConfig{},
		&PointsTransactionHistory{},
	); err != nil {
		return err
	}

	logger.Info("Database initialized successfully")
	return nil
}

func initConsulClient() error {
	config := api.DefaultConfig()
	config.Address = viper.GetString("consul.address")

	var err error
	consulClient, err = api.NewClient(config)
	if err != nil {
		return err
	}

	logger.Info("Consul client initialized successfully")
	return nil
}

func initRedisClient() error {
	redisClient = redis.NewClient(&redis.Options{
		Addr:     viper.GetString("redis.address"),
		Password: viper.GetString("redis.password"),
		DB:       viper.GetInt("redis.db"),
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := redisClient.Ping(ctx).Err(); err != nil {
		return err
	}

	logger.Info("Redis client initialized successfully")
	return nil
}

func registerService() error {
	registration := &api.AgentServiceRegistration{
		ID:      "blockchain-service",
		Name:    "blockchain-service",
		Port:    viper.GetInt("server.port"),
		Address: "localhost",
		Tags:    []string{"blockchain", "api"},
		// 暂时禁用健康检查，避免服务被自动注销
		// Check: &api.AgentServiceCheck{
		// 	HTTP:                           fmt.Sprintf("http://localhost:%s/health", viper.GetString("server.port")),
		// 	Interval:                       "30s",
		// 	Timeout:                        "10s",
		// 	DeregisterCriticalServiceAfter: "60s",
		// },
	}

	return consulClient.Agent().ServiceRegister(registration)
}

func deregisterService() error {
	return consulClient.Agent().ServiceDeregister("blockchain-service")
}

func setupRouter() *gin.Engine {
	router := gin.Default()

	// 中间件
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(corsMiddleware())

	// 健康检查
	router.GET("/health", healthCheck)

	// 区块链服务路由组 - 完全兼容原有系统
	blockchain := router.Group("/blockchain")
	{
		// 区块链证书相关
		certificates := blockchain.Group("/certificates")
		{
			certificates.POST("/", createCertificate)
			certificates.GET("/", listCertificates)
			certificates.GET("/:id", getCertificate)
			certificates.PUT("/:id", updateCertificate)
			certificates.DELETE("/:id", deleteCertificate)
			certificates.GET("/:id/verify", verifyCertificate)
		}

		// 区块链交易相关
		transactions := blockchain.Group("/transactions")
		{
			transactions.GET("/", listTransactions)
			transactions.GET("/:id", getTransaction)
			transactions.POST("/", createTransaction)
		}

		// 钱包相关
		wallets := blockchain.Group("/wallets")
		{
			wallets.POST("/", createWallet)
			wallets.GET("/", listWallets)
			wallets.GET("/:id", getWallet)
			wallets.GET("/:id/balance", getWalletBalance)
		}

		// 智能合约相关
		contracts := blockchain.Group("/contracts")
		{
			contracts.POST("/", deployContract)
			contracts.GET("/", listContracts)
			contracts.GET("/:id", getContract)
			contracts.POST("/:id/invoke", invokeContract)
			contracts.POST("/:id/query", queryContract)
		}

		// 积分交易相关 (兼容原有API)
		points := blockchain.Group("/points")
		{
			points.POST("/tx", savePointsTransaction)
			points.GET("/tx/:id", getPointsTransaction)
			points.GET("/balance/:userId", getPointsBalance)
			points.POST("/transfer", transferPoints)
		}

		// 简历相关 (兼容原有API)
		resume := blockchain.Group("/resume")
		{
			resume.POST("/", createResumeOnBlockchain)
			resume.GET("/:id", getResumeFromBlockchain)
			resume.DELETE("/:id", deleteResumeFromBlockchain)
		}
	}

	// API路由组 (保持原有兼容性)
	api := router.Group("/api/v1")
	{
		// 区块链证书相关
		certificates := api.Group("/certificates")
		{
			certificates.POST("/", createCertificate)
			certificates.GET("/", listCertificates)
			certificates.GET("/:id", getCertificate)
			certificates.PUT("/:id", updateCertificate)
			certificates.DELETE("/:id", deleteCertificate)
			certificates.GET("/:id/verify", verifyCertificate)
		}

		// 区块链交易相关
		transactions := api.Group("/transactions")
		{
			transactions.GET("/", listTransactions)
			transactions.GET("/:id", getTransaction)
			transactions.POST("/", createTransaction)
		}

		// 钱包相关
		wallets := api.Group("/wallets")
		{
			wallets.POST("/", createWallet)
			wallets.GET("/", listWallets)
			wallets.GET("/:id", getWallet)
			wallets.GET("/:id/balance", getWalletBalance)
		}

		// 智能合约相关
		contracts := api.Group("/contracts")
		{
			contracts.POST("/", deployContract)
			contracts.GET("/", listContracts)
			contracts.GET("/:id", getContract)
			contracts.POST("/:id/invoke", invokeContract)
			contracts.POST("/:id/query", queryContract)
		}

		// 积分交易相关 (兼容原有API)
		points := api.Group("/points")
		{
			points.POST("/tx", savePointsTransaction)
			points.GET("/tx/:id", getPointsTransaction)
			points.GET("/balance/:userId", getPointsBalance)
			points.POST("/transfer", transferPoints)
		}

		// 简历相关 (兼容原有API)
		resume := api.Group("/resume")
		{
			resume.POST("/", createResumeOnBlockchain)
			resume.GET("/:id", getResumeFromBlockchain)
			resume.DELETE("/:id", deleteResumeFromBlockchain)
		}
	}

	return router
}

func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"service":   "blockchain",
		"timestamp": time.Now().Unix(),
		"version":   "2.0.0",
		"provider":  "tencent-cloud",
	})
}
