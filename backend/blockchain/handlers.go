package main

import (
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// 创建区块链证书
func createCertificate(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		Type           string `json:"type" binding:"required"`
		Title          string `json:"title" binding:"required"`
		Description    string `json:"description"`
		Content        string `json:"content" binding:"required"`
		BlockchainType string `json:"blockchain_type" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 生成内容哈希
	contentHash := generateContentHash(req.Content)

	// 创建证书记录
	certificate := BlockchainCertificate{
		ID:             uuid.New().String(),
		UserID:         userID,
		Type:           CertificateType(req.Type),
		Title:          req.Title,
		Description:    req.Description,
		Content:        req.Content,
		Hash:           contentHash,
		BlockchainType: BlockchainType(req.BlockchainType),
		Status:         TransactionStatusPending,
	}

	if err := db.Create(&certificate).Error; err != nil {
		logger.Errorf("Failed to create certificate: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create certificate"})
		return
	}

	// 模拟区块链交易
	go func() {
		// 模拟区块链交易延迟
		time.Sleep(2 * time.Second)

		// 更新交易哈希和状态
		db.Model(&certificate).Updates(map[string]interface{}{
			"transaction_hash": "mock_tx_" + certificate.ID,
			"status":           TransactionStatusConfirmed,
			"block_number":     12345,
		})
	}()

	c.JSON(http.StatusCreated, gin.H{
		"message":     "Certificate created successfully",
		"certificate": certificate,
	})
}

// 获取证书列表
func listCertificates(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var certificates []BlockchainCertificate
	query := db.Where("user_id = ?", userID)

	// 添加过滤条件
	if certType := c.Query("type"); certType != "" {
		query = query.Where("type = ?", certType)
	}

	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	if err := query.Order("created_at DESC").Find(&certificates).Error; err != nil {
		logger.Errorf("Failed to list certificates: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list certificates"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"certificates": certificates})
}

// 获取单个证书
func getCertificate(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	certID := c.Param("id")
	var certificate BlockchainCertificate

	if err := db.Where("id = ? AND user_id = ?", certID, userID).First(&certificate).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Certificate not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"certificate": certificate})
}

// 更新证书
func updateCertificate(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	certID := c.Param("id")
	var certificate BlockchainCertificate

	if err := db.Where("id = ? AND user_id = ?", certID, userID).First(&certificate).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Certificate not found"})
		return
	}

	var req struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		Content     string `json:"content"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 更新证书信息
	updates := make(map[string]interface{})
	if req.Title != "" {
		updates["title"] = req.Title
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}
	if req.Content != "" {
		updates["content"] = req.Content
		updates["hash"] = generateContentHash(req.Content)
	}

	if err := db.Model(&certificate).Updates(updates).Error; err != nil {
		logger.Errorf("Failed to update certificate: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update certificate"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Certificate updated successfully"})
}

// 删除证书
func deleteCertificate(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	certID := c.Param("id")
	var certificate BlockchainCertificate

	if err := db.Where("id = ? AND user_id = ?", certID, userID).First(&certificate).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Certificate not found"})
		return
	}

	if err := db.Delete(&certificate).Error; err != nil {
		logger.Errorf("Failed to delete certificate: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete certificate"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Certificate deleted successfully"})
}

// 验证证书
func verifyCertificate(c *gin.Context) {
	certID := c.Param("id")
	var certificate BlockchainCertificate

	if err := db.Where("id = ?", certID).First(&certificate).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Certificate not found"})
		return
	}

	// 验证内容哈希
	expectedHash := generateContentHash(certificate.Content)
	isValid := certificate.Hash == expectedHash

	// 模拟区块链状态查询
	var blockchainStatus string
	if certificate.TransactionHash != "" {
		blockchainStatus = "confirmed"
	} else {
		blockchainStatus = "pending"
	}

	c.JSON(http.StatusOK, gin.H{
		"certificate":       certificate,
		"is_valid":          isValid,
		"blockchain_status": blockchainStatus,
	})
}

// 获取交易列表
func listTransactions(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var transactions []BlockchainTransaction
	query := db.Where("user_id = ?", userID)

	if err := query.Order("created_at DESC").Find(&transactions).Error; err != nil {
		logger.Errorf("Failed to list transactions: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list transactions"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"transactions": transactions})
}

// 获取单个交易
func getTransaction(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	txID := c.Param("id")
	var transaction BlockchainTransaction

	if err := db.Where("id = ? AND user_id = ?", txID, userID).First(&transaction).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Transaction not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"transaction": transaction})
}

// 创建交易
func createTransaction(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		Type           string `json:"type" binding:"required"`
		FromAddress    string `json:"from_address" binding:"required"`
		ToAddress      string `json:"to_address" binding:"required"`
		Value          string `json:"value" binding:"required"`
		BlockchainType string `json:"blockchain_type" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	transaction := BlockchainTransaction{
		ID:             uuid.New().String(),
		UserID:         userID,
		Type:           req.Type,
		BlockchainType: BlockchainType(req.BlockchainType),
		FromAddress:    req.FromAddress,
		ToAddress:      req.ToAddress,
		Value:          req.Value,
		Status:         TransactionStatusPending,
	}

	if err := db.Create(&transaction).Error; err != nil {
		logger.Errorf("Failed to create transaction: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transaction"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":     "Transaction created successfully",
		"transaction": transaction,
	})
}

// 创建钱包
func createWallet(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		BlockchainType string `json:"blockchain_type" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 生成钱包地址和私钥（这里简化处理）
	walletAddress := generateWalletAddress()
	privateKey := generatePrivateKey()

	wallet := Wallet{
		ID:             uuid.New().String(),
		UserID:         userID,
		Address:        walletAddress,
		PrivateKey:     privateKey,
		BlockchainType: BlockchainType(req.BlockchainType),
		Balance:        "0",
		IsActive:       true,
	}

	if err := db.Create(&wallet).Error; err != nil {
		logger.Errorf("Failed to create wallet: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create wallet"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Wallet created successfully",
		"wallet":  wallet,
	})
}

// 获取钱包列表
func listWallets(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var wallets []Wallet
	if err := db.Where("user_id = ?", userID).Find(&wallets).Error; err != nil {
		logger.Errorf("Failed to list wallets: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list wallets"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"wallets": wallets})
}

// 获取单个钱包
func getWallet(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	walletID := c.Param("id")
	var wallet Wallet

	if err := db.Where("id = ? AND user_id = ?", walletID, userID).First(&wallet).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wallet not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"wallet": wallet})
}

// 获取钱包余额
func getWalletBalance(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	walletID := c.Param("id")
	var wallet Wallet

	if err := db.Where("id = ? AND user_id = ?", walletID, userID).First(&wallet).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wallet not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"wallet_id": wallet.ID,
		"address":   wallet.Address,
		"balance":   wallet.Balance,
	})
}

// 部署智能合约
func deployContract(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		Name           string `json:"name" binding:"required"`
		BlockchainType string `json:"blockchain_type" binding:"required"`
		ABI            string `json:"abi" binding:"required"`
		Bytecode       string `json:"bytecode" binding:"required"`
		Version        string `json:"version"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	contract := SmartContract{
		ID:             uuid.New().String(),
		Name:           req.Name,
		Address:        generateContractAddress(),
		BlockchainType: BlockchainType(req.BlockchainType),
		ABI:            req.ABI,
		Bytecode:       req.Bytecode,
		Version:        req.Version,
		IsActive:       true,
	}

	if err := db.Create(&contract).Error; err != nil {
		logger.Errorf("Failed to deploy contract: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to deploy contract"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":  "Contract deployed successfully",
		"contract": contract,
	})
}

// 获取智能合约列表
func listContracts(c *gin.Context) {
	var contracts []SmartContract
	if err := db.Where("is_active = ?", true).Find(&contracts).Error; err != nil {
		logger.Errorf("Failed to list contracts: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list contracts"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"contracts": contracts})
}

// 获取单个智能合约
func getContract(c *gin.Context) {
	contractID := c.Param("id")
	var contract SmartContract

	if err := db.Where("id = ?", contractID).First(&contract).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contract not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"contract": contract})
}

// 调用智能合约
func invokeContract(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	contractID := c.Param("id")
	var contract SmartContract

	if err := db.Where("id = ?", contractID).First(&contract).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contract not found"})
		return
	}

	var req struct {
		Function string   `json:"function" binding:"required"`
		Args     []string `json:"args"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 模拟智能合约调用
	txid := "mock_tx_" + uuid.New().String()

	c.JSON(http.StatusOK, gin.H{
		"message": "Contract invoked successfully",
		"txid":    txid,
	})
}

// 查询智能合约
func queryContract(c *gin.Context) {
	contractID := c.Param("id")
	var contract SmartContract

	if err := db.Where("id = ?", contractID).First(&contract).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contract not found"})
		return
	}

	var req struct {
		Function string   `json:"function" binding:"required"`
		Args     []string `json:"args"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 模拟智能合约查询
	result := map[string]interface{}{
		"function": req.Function,
		"args":     req.Args,
		"result":   "mock_query_result",
	}

	c.JSON(http.StatusOK, gin.H{
		"result": result,
	})
}

// ========== 兼容原有API的处理函数 ==========

// 保存积分交易记录到区块链
func savePointsTransaction(c *gin.Context) {
	var txHistory PointsTransactionHistory
	if err := c.ShouldBindJSON(&txHistory); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 生成交易ID
	if txHistory.TransactionHistoryID == "" {
		txHistory.TransactionHistoryID = uuid.New().String()
	}

	// 设置创建时间
	if txHistory.CreateTime.IsZero() {
		txHistory.CreateTime = time.Now()
	}

	// 设置区块链类型为腾讯云
	txHistory.BlockchainType = BlockchainTypeTencent
	txHistory.Status = TransactionStatusPending

	// 保存到数据库
	if err := db.Create(&txHistory).Error; err != nil {
		logger.Errorf("Failed to save points transaction: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save transaction"})
		return
	}

	// 模拟区块链交易
	go func() {
		// 模拟区块链交易延迟
		time.Sleep(2 * time.Second)

		// 更新交易哈希和状态
		db.Model(&txHistory).Updates(map[string]interface{}{
			"transaction_hash": "mock_tx_" + txHistory.TransactionHistoryID,
			"status":           TransactionStatusConfirmed,
		})
	}()

	response := PointsTxSaveResp{
		TxId:    txHistory.TransactionHistoryID,
		Success: true,
	}

	c.JSON(http.StatusCreated, gin.H{
		"data": response,
	})
}

// 查询积分交易记录详细信息
func getPointsTransaction(c *gin.Context) {
	transactionHistoryId := c.Param("id")
	var txHistory PointsTransactionHistory

	if err := db.Where("transaction_history_id = ?", transactionHistoryId).First(&txHistory).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Transaction not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": txHistory,
	})
}

// 获取用户积分余额
func getPointsBalance(c *gin.Context) {
	userId := c.Param("userId")

	// 查询用户的积分余额
	var totalPoints int64
	if err := db.Model(&PointsTransactionHistory{}).
		Where("to_user_id = ? AND status = ?", userId, TransactionStatusConfirmed).
		Select("COALESCE(SUM(transaction_point), 0)").
		Scan(&totalPoints).Error; err != nil {
		logger.Errorf("Failed to get points balance: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get balance"})
		return
	}

	// 减去转出的积分
	var sentPoints int64
	if err := db.Model(&PointsTransactionHistory{}).
		Where("from_user_id = ? AND status = ?", userId, TransactionStatusConfirmed).
		Select("COALESCE(SUM(transaction_point), 0)").
		Scan(&sentPoints).Error; err != nil {
		logger.Errorf("Failed to get sent points: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get balance"})
		return
	}

	balance := totalPoints - sentPoints
	if balance < 0 {
		balance = 0
	}

	c.JSON(http.StatusOK, gin.H{
		"data": balance,
	})
}

// 积分转账
func transferPoints(c *gin.Context) {
	var req struct {
		FromUserId string `json:"fromUserId" binding:"required"`
		ToUserId   string `json:"toUserId" binding:"required"`
		Points     int    `json:"points" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查余额
	var balance int64
	if err := db.Model(&PointsTransactionHistory{}).
		Where("to_user_id = ? AND status = ?", req.FromUserId, TransactionStatusConfirmed).
		Select("COALESCE(SUM(transaction_point), 0)").
		Scan(&balance).Error; err != nil {
		logger.Errorf("Failed to get balance: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get balance"})
		return
	}

	var sentPoints int64
	if err := db.Model(&PointsTransactionHistory{}).
		Where("from_user_id = ? AND status = ?", req.FromUserId, TransactionStatusConfirmed).
		Select("COALESCE(SUM(transaction_point), 0)").
		Scan(&sentPoints).Error; err != nil {
		logger.Errorf("Failed to get sent points: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get balance"})
		return
	}

	availableBalance := balance - sentPoints
	if availableBalance < int64(req.Points) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Insufficient balance"})
		return
	}

	// 创建转账交易记录
	txHistory := PointsTransactionHistory{
		TransactionHistoryID: uuid.New().String(),
		FromUserId:           req.FromUserId,
		FromUserSource:       2, // 个人端
		ToUserId:             req.ToUserId,
		ToUserSource:         2, // 个人端
		TransactionPoint:     req.Points,
		TransactionCode:      1, // 转账
		TransactionContent:   "积分转账",
		CreateTime:           time.Now(),
		BlockchainType:       BlockchainTypeTencent,
		Status:               TransactionStatusPending,
	}

	// 保存到数据库
	if err := db.Create(&txHistory).Error; err != nil {
		logger.Errorf("Failed to create transfer transaction: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transfer"})
		return
	}

	// 模拟区块链交易
	go func() {
		// 模拟区块链交易延迟
		time.Sleep(2 * time.Second)

		// 更新交易哈希和状态
		db.Model(&txHistory).Updates(map[string]interface{}{
			"transaction_hash": "mock_tx_" + txHistory.TransactionHistoryID,
			"status":           TransactionStatusConfirmed,
		})
	}()

	c.JSON(http.StatusOK, gin.H{
		"message": "Transfer initiated successfully",
		"txId":    txHistory.TransactionHistoryID,
	})
}

// 创建简历到区块链
func createResumeOnBlockchain(c *gin.Context) {
	resumeId := c.Query("resumeId")
	if resumeId == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "resumeId is required"})
		return
	}

	var resumeModel ResumeModel
	if err := c.ShouldBindJSON(&resumeModel); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	resumeModel.ID = resumeId
	resumeModel.Hash = generateContentHash(resumeModel.Content)
	resumeModel.Status = "active"
	resumeModel.CreatedAt = time.Now()
	resumeModel.UpdatedAt = time.Now()

	// 保存到数据库
	if err := db.Create(&resumeModel).Error; err != nil {
		logger.Errorf("Failed to create resume: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create resume"})
		return
	}

	// 模拟区块链交易
	go func() {
		// 模拟区块链交易延迟
		time.Sleep(2 * time.Second)

		// 更新区块号
		db.Model(&resumeModel).Update("block_number", 12345)
	}()

	c.JSON(http.StatusOK, gin.H{
		"message":  "Resume created successfully",
		"resumeId": resumeModel.ID,
	})
}

// 从区块链查询简历
func getResumeFromBlockchain(c *gin.Context) {
	resumeId := c.Param("id")
	var resumeModel ResumeModel

	if err := db.Where("id = ?", resumeId).First(&resumeModel).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Resume not found"})
		return
	}

	// 模拟区块链验证
	go func() {
		logger.Infof("Mock: Verifying resume %s on blockchain", resumeModel.ID)
	}()

	c.JSON(http.StatusOK, gin.H{
		"data": resumeModel,
	})
}

// 从区块链删除简历
func deleteResumeFromBlockchain(c *gin.Context) {
	resumeId := c.Param("id")
	var resumeModel ResumeModel

	if err := db.Where("id = ?", resumeId).First(&resumeModel).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Resume not found"})
		return
	}

	// 软删除
	resumeModel.Status = "deleted"
	resumeModel.UpdatedAt = time.Now()

	if err := db.Save(&resumeModel).Error; err != nil {
		logger.Errorf("Failed to delete resume: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete resume"})
		return
	}

	// 模拟区块链删除
	go func() {
		logger.Infof("Mock: Deleting resume %s from blockchain", resumeModel.ID)
	}()

	c.JSON(http.StatusOK, gin.H{
		"message": "Resume deleted successfully",
	})
}

// 辅助函数
func generateContentHash(content string) string {
	hash := sha256.Sum256([]byte(content))
	return hex.EncodeToString(hash[:])
}

func generateWalletAddress() string {
	// 简化实现，实际应该使用椭圆曲线加密
	return "0x" + hex.EncodeToString([]byte(uuid.New().String()))[:40]
}

func generatePrivateKey() string {
	// 简化实现，实际应该使用椭圆曲线加密
	return hex.EncodeToString([]byte(uuid.New().String()))[:64]
}

func generateContractAddress() string {
	// 简化实现，实际应该使用椭圆曲线加密
	return "0x" + hex.EncodeToString([]byte(uuid.New().String()))[:40]
}

// 从上下文获取用户ID
func getUserIDFromContext(c *gin.Context) uint {
	// 从JWT token中获取用户ID
	// 这里简化处理，实际应该从JWT中解析
	userID, exists := c.Get("user_id")
	if !exists {
		return 0
	}
	if id, ok := userID.(uint); ok {
		return id
	}
	return 0
}
