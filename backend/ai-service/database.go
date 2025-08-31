package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/neo4j/neo4j-go-driver/v5/neo4j"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DatabaseManager 数据库管理器
type DatabaseManager struct {
	MySQL      *gorm.DB
	PostgreSQL *gorm.DB
	Neo4j      neo4j.Driver
	Redis      *redis.Client
}

// NewDatabaseManager 创建数据库管理器
func NewDatabaseManager() (*DatabaseManager, error) {
	manager := &DatabaseManager{}

	// 初始化MySQL连接
	mysqlDB, err := initMySQL()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize MySQL: %v", err)
	}
	manager.MySQL = mysqlDB

	// 初始化PostgreSQL连接
	postgresDB, err := initPostgreSQL()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize PostgreSQL: %v", err)
	}
	manager.PostgreSQL = postgresDB

	// 初始化Neo4j连接
	neo4jDriver, err := initNeo4j()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Neo4j: %v", err)
	}
	manager.Neo4j = neo4jDriver

	// 初始化Redis连接
	redisClient, err := initRedis()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Redis: %v", err)
	}
	manager.Redis = redisClient

	return manager, nil
}

// initMySQL 初始化MySQL连接
func initMySQL() (*gorm.DB, error) {
	dsn := "jobfirst:jobfirst123@tcp(mysql:3306)/jobfirst?charset=utf8mb4&parseTime=True&loc=Local"

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, err
	}

	// 配置连接池
	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	log.Printf("MySQL connected successfully")
	return db, nil
}

// initPostgreSQL 初始化PostgreSQL连接
func initPostgreSQL() (*gorm.DB, error) {
	dsn := "host=postgresql port=5432 user=jobfirst password=jobfirst123 dbname=jobfirst_advanced sslmode=disable TimeZone=Asia/Shanghai"

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, err
	}

	// 配置连接池
	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	log.Printf("PostgreSQL connected successfully")
	return db, nil
}

// initNeo4j 初始化Neo4j连接
func initNeo4j() (neo4j.Driver, error) {
	uri := "neo4j://neo4j:7687"
	
	driver, err := neo4j.NewDriver(uri, neo4j.BasicAuth("neo4j", "jobfirst123", ""))
	if err != nil {
		return nil, err
	}

	// 测试连接
	err = driver.VerifyConnectivity()
	if err != nil {
		return nil, err
	}

	log.Printf("Neo4j connected successfully")
	return driver, nil
}

// initRedis 初始化Redis连接
func initRedis() (*redis.Client, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     "redis:6379",
		Password: "",
		DB:       0,
	})

	// 测试连接
	ctx := context.Background()
	_, err := client.Ping(ctx).Result()
	if err != nil {
		return nil, err
	}

	log.Printf("Redis connected successfully")
	return client, nil
}

// Close 关闭所有数据库连接
func (dm *DatabaseManager) Close() error {
	var errors []error

	// 关闭MySQL连接
	if dm.MySQL != nil {
		sqlDB, err := dm.MySQL.DB()
		if err == nil {
			errors = append(errors, sqlDB.Close())
		}
	}

	// 关闭PostgreSQL连接
	if dm.PostgreSQL != nil {
		sqlDB, err := dm.PostgreSQL.DB()
		if err == nil {
			errors = append(errors, sqlDB.Close())
		}
	}

	// 关闭Neo4j连接
	if dm.Neo4j != nil {
		errors = append(errors, dm.Neo4j.Close())
	}

	// 关闭Redis连接
	if dm.Redis != nil {
		errors = append(errors, dm.Redis.Close())
	}

	// 返回第一个错误
	if len(errors) > 0 {
		return errors[0]
	}
	return nil
}

// HealthCheck 健康检查
func (dm *DatabaseManager) HealthCheck() map[string]bool {
	health := make(map[string]bool)

	// MySQL健康检查
	if dm.MySQL != nil {
		sqlDB, err := dm.MySQL.DB()
		if err == nil {
			health["mysql"] = sqlDB.Ping() == nil
		} else {
			health["mysql"] = false
		}
	} else {
		health["mysql"] = false
	}

	// PostgreSQL健康检查
	if dm.PostgreSQL != nil {
		sqlDB, err := dm.PostgreSQL.DB()
		if err == nil {
			health["postgresql"] = sqlDB.Ping() == nil
		} else {
			health["postgresql"] = false
		}
	} else {
		health["postgresql"] = false
	}

	// Neo4j健康检查
	if dm.Neo4j != nil {
		health["neo4j"] = dm.Neo4j.VerifyConnectivity() == nil
	} else {
		health["neo4j"] = false
	}

	// Redis健康检查
	if dm.Redis != nil {
		ctx := context.Background()
		_, err := dm.Redis.Ping(ctx).Result()
		health["redis"] = err == nil
	} else {
		health["redis"] = false
	}

	return health
}
