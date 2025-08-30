package main

import (
	"time"
)

// 区块链类型
type BlockchainType string

const (
	BlockchainTypeEthereum BlockchainType = "ethereum"
	BlockchainTypePolygon  BlockchainType = "polygon"
	BlockchainTypeBSC      BlockchainType = "bsc"
	BlockchainTypeTencent  BlockchainType = "tencent" // 新增腾讯云区块链类型
)

// 交易状态
type TransactionStatus string

const (
	TransactionStatusPending   TransactionStatus = "pending"
	TransactionStatusConfirmed TransactionStatus = "confirmed"
	TransactionStatusFailed    TransactionStatus = "failed"
)

// 证书类型
type CertificateType string

const (
	CertificateTypeResume     CertificateType = "resume"
	CertificateTypeEducation  CertificateType = "education"
	CertificateTypeExperience CertificateType = "experience"
	CertificateTypeSkill      CertificateType = "skill"
)

// 区块链证书模型
type BlockchainCertificate struct {
	ID              string            `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID          uint              `json:"user_id" gorm:"not null;index"`
	Type            CertificateType   `json:"type" gorm:"type:varchar(50);not null"`
	Title           string            `json:"title" gorm:"not null"`
	Description     string            `json:"description" gorm:"type:text"`
	Content         string            `json:"content" gorm:"type:text"`
	Hash            string            `json:"hash" gorm:"type:varchar(66);uniqueIndex"`
	BlockchainType  BlockchainType    `json:"blockchain_type" gorm:"type:varchar(20);not null"`
	TransactionHash string            `json:"transaction_hash" gorm:"type:varchar(66)"`
	BlockNumber     uint64            `json:"block_number"`
	Status          TransactionStatus `json:"status" gorm:"type:varchar(20);default:'pending'"`
	GasUsed         uint64            `json:"gas_used"`
	GasPrice        uint64            `json:"gas_price"`
	CreatedAt       time.Time         `json:"created_at"`
	UpdatedAt       time.Time         `json:"updated_at"`
}

// 区块链交易记录模型
type BlockchainTransaction struct {
	ID              string            `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID          uint              `json:"user_id" gorm:"not null;index"`
	Type            string            `json:"type" gorm:"type:varchar(50);not null"`
	TransactionHash string            `json:"transaction_hash" gorm:"type:varchar(66);uniqueIndex"`
	BlockchainType  BlockchainType    `json:"blockchain_type" gorm:"type:varchar(20);not null"`
	FromAddress     string            `json:"from_address" gorm:"type:varchar(42)"`
	ToAddress       string            `json:"to_address" gorm:"type:varchar(42)"`
	Value           string            `json:"value" gorm:"type:varchar(50)"`
	GasUsed         uint64            `json:"gas_used"`
	GasPrice        uint64            `json:"gas_price"`
	BlockNumber     uint64            `json:"block_number"`
	Status          TransactionStatus `json:"status" gorm:"type:varchar(20);default:'pending'"`
	Error           string            `json:"error" gorm:"type:text"`
	CreatedAt       time.Time         `json:"created_at"`
	UpdatedAt       time.Time         `json:"updated_at"`
}

// 钱包模型
type Wallet struct {
	ID             string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID         uint           `json:"user_id" gorm:"uniqueIndex;not null"`
	Address        string         `json:"address" gorm:"type:varchar(42);uniqueIndex;not null"`
	PrivateKey     string         `json:"private_key" gorm:"type:varchar(66);not null"`
	BlockchainType BlockchainType `json:"blockchain_type" gorm:"type:varchar(20);not null"`
	Balance        string         `json:"balance" gorm:"type:varchar(50);default:'0'"`
	IsActive       bool           `json:"is_active" gorm:"default:true"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// 智能合约模型
type SmartContract struct {
	ID             string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	Name           string         `json:"name" gorm:"not null"`
	Address        string         `json:"address" gorm:"type:varchar(42);uniqueIndex;not null"`
	BlockchainType BlockchainType `json:"blockchain_type" gorm:"type:varchar(20);not null"`
	ABI            string         `json:"abi" gorm:"type:text"`
	Bytecode       string         `json:"bytecode" gorm:"type:text"`
	Version        string         `json:"version" gorm:"type:varchar(20)"`
	IsActive       bool           `json:"is_active" gorm:"default:true"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// 区块链配置模型
type BlockchainConfig struct {
	ID             string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	BlockchainType BlockchainType `json:"blockchain_type" gorm:"type:varchar(20);uniqueIndex;not null"`
	NetworkName    string         `json:"network_name" gorm:"not null"`
	RPCURL         string         `json:"rpc_url" gorm:"type:varchar(200);not null"`
	ChainID        uint64         `json:"chain_id" gorm:"not null"`
	CurrencySymbol string         `json:"currency_symbol" gorm:"type:varchar(10)"`
	ExplorerURL    string         `json:"explorer_url" gorm:"type:varchar(200)"`
	GasLimit       uint64         `json:"gas_limit" gorm:"default:21000"`
	IsActive       bool           `json:"is_active" gorm:"default:true"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// 积分交易记录模型 (兼容原有API)
type PointsTransactionHistory struct {
	TransactionHistoryID string    `json:"transactionHistoryId" gorm:"primaryKey;type:varchar(36)"`
	FromUserId           string    `json:"fromUserId" gorm:"type:varchar(50);not null"`
	FromUserSource       int       `json:"fromUserSource" gorm:"not null"` // 1-管理端，2-个人端，3-企业端
	ToUserId             string    `json:"toUserId" gorm:"type:varchar(50);not null"`
	ToUserSource         int       `json:"toUserSource" gorm:"not null"` // 1-管理端，2-个人端，3-企业端
	TransactionPoint     int       `json:"transactionPoint" gorm:"not null"`
	TransactionCode      int       `json:"transactionCode" gorm:"not null"` // 交易类型码
	TransactionContent   string    `json:"transactionContent" gorm:"type:text"`
	CreateTime           time.Time `json:"createTime" gorm:"not null"`
	// 区块链相关字段
	TransactionHash      string            `json:"transactionHash" gorm:"type:varchar(66)"`
	BlockNumber          uint64            `json:"blockNumber"`
	Status               TransactionStatus `json:"status" gorm:"type:varchar(20);default:'pending'"`
	BlockchainType       BlockchainType    `json:"blockchainType" gorm:"type:varchar(20);default:'tencent'"`
}

// 积分交易保存响应模型 (兼容原有API)
type PointsTxSaveResp struct {
	TxId    string `json:"txId"`
	Success bool   `json:"success"`
}

// 简历模型 (兼容原有API)
type ResumeModel struct {
	ID          string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID      string    `json:"userId" gorm:"type:varchar(50);not null"`
	Title       string    `json:"title" gorm:"not null"`
	Content     string    `json:"content" gorm:"type:text"`
	Hash        string    `json:"hash" gorm:"type:varchar(66);uniqueIndex"`
	BlockNumber uint64    `json:"blockNumber"`
	Status      string    `json:"status" gorm:"type:varchar(20);default:'active'"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// 腾讯云区块链集群信息
type TencentClusterInfo struct {
	ClusterID       string `json:"clusterId"`
	ClusterName     string `json:"clusterName"`
	Status          string `json:"status"`
	NodeCount       int    `json:"nodeCount"`
	ChannelCount    int    `json:"channelCount"`
	ChaincodeCount  int    `json:"chaincodeCount"`
	TotalTxs        int    `json:"totalTxs"`
	NetworkVersion  string `json:"networkVersion"`
	CreateTime      string `json:"createTime"`
}

// 腾讯云区块链通道信息
type TencentChannelInfo struct {
	ChannelID      string `json:"channelId"`
	ChannelName    string `json:"channelName"`
	Status         string `json:"status"`
	PeerCount      int    `json:"peerCount"`
	BlockHeight    uint64 `json:"blockHeight"`
	TotalTxs       int    `json:"totalTxs"`
	CreateTime     string `json:"createTime"`
}

// 腾讯云区块链智能合约信息
type TencentChaincodeInfo struct {
	ChaincodeID    string `json:"chaincodeId"`
	ChaincodeName  string `json:"chaincodeName"`
	Version        string `json:"version"`
	Status         string `json:"status"`
	Path           string `json:"path"`
	Language       string `json:"language"`
	CreateTime     string `json:"createTime"`
}
