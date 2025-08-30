package main

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// 创建处理任务
func createTask(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		TaskType     string `json:"task_type" binding:"required"`
		DocumentType string `json:"document_type" binding:"required"`
		SourceFormat string `json:"source_format" binding:"required"`
		TargetFormat string `json:"target_format"`
		SourceFileID string `json:"source_file_id" binding:"required"`
		Metadata     string `json:"metadata"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 创建任务
	task := DocumentTask{
		ID:           uuid.New().String(),
		UserID:       userID,
		TaskType:     req.TaskType,
		DocumentType: DocumentType(req.DocumentType),
		SourceFormat: DocumentFormat(req.SourceFormat),
		TargetFormat: DocumentFormat(req.TargetFormat),
		SourceFileID: req.SourceFileID,
		Status:       ProcessingStatusPending,
		Progress:     0,
		Metadata:     req.Metadata,
	}

	if err := db.Create(&task).Error; err != nil {
		logger.Errorf("Failed to create task: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create task"})
		return
	}

	// 异步处理任务
	go processTask(&task)

	c.JSON(http.StatusCreated, gin.H{
		"message": "Task created successfully",
		"task":    task,
	})
}

// 获取任务列表
func listTasks(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var tasks []DocumentTask
	query := db.Where("user_id = ?", userID)
	
	// 添加过滤条件
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	
	if taskType := c.Query("task_type"); taskType != "" {
		query = query.Where("task_type = ?", taskType)
	}

	if err := query.Order("created_at DESC").Limit(50).Find(&tasks).Error; err != nil {
		logger.Errorf("Failed to list tasks: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list tasks"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"tasks": tasks})
}

// 获取单个任务
func getTask(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	taskID := c.Param("id")
	if taskID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Task ID is required"})
		return
	}

	var task DocumentTask
	if err := db.Where("id = ? AND user_id = ?", taskID, userID).First(&task).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Task not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"task": task})
}

// 取消任务
func cancelTask(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	taskID := c.Param("id")
	if taskID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Task ID is required"})
		return
	}

	var task DocumentTask
	if err := db.Where("id = ? AND user_id = ?", taskID, userID).First(&task).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Task not found"})
		return
	}

	// 只能取消待处理或处理中的任务
	if task.Status != ProcessingStatusPending && task.Status != ProcessingStatusProcessing {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot cancel completed or failed task"})
		return
	}

	task.Status = ProcessingStatusFailed
	task.Error = "Task cancelled by user"
	task.CompletedAt = &time.Time{}

	if err := db.Save(&task).Error; err != nil {
		logger.Errorf("Failed to cancel task: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to cancel task"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Task cancelled successfully",
		"task":    task,
	})
}

// 文档转换
func convertDocument(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		SourceFileID string `json:"source_file_id" binding:"required"`
		SourceFormat string `json:"source_format" binding:"required"`
		TargetFormat string `json:"target_format" binding:"required"`
		ConfigID     string `json:"config_id"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 创建转换任务
	task := DocumentTask{
		ID:           uuid.New().String(),
		UserID:       userID,
		TaskType:     "conversion",
		DocumentType: DocumentTypeOther,
		SourceFormat: DocumentFormat(req.SourceFormat),
		TargetFormat: DocumentFormat(req.TargetFormat),
		SourceFileID: req.SourceFileID,
		Status:       ProcessingStatusPending,
		Progress:     0,
	}

	if err := db.Create(&task).Error; err != nil {
		logger.Errorf("Failed to create conversion task: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create conversion task"})
		return
	}

	// 异步执行转换
	go convertDocumentAsync(&task)

	c.JSON(http.StatusCreated, gin.H{
		"message": "Document conversion started",
		"task":    task,
	})
}

// 获取支持的格式
func getSupportedFormats(c *gin.Context) {
	formats := gin.H{
		"input": []string{"pdf", "doc", "docx", "txt", "rtf", "html", "md"},
		"output": []string{"pdf", "docx", "txt", "html", "md"},
		"conversions": map[string][]string{
			"pdf":  {"docx", "txt", "html"},
			"doc":  {"pdf", "docx", "txt"},
			"docx": {"pdf", "txt", "html", "md"},
			"txt":  {"pdf", "docx", "html"},
			"rtf":  {"pdf", "docx", "txt"},
			"html": {"pdf", "docx", "txt", "md"},
			"md":   {"pdf", "docx", "html"},
		},
	}

	c.JSON(http.StatusOK, formats)
}

// 获取转换配置
func getConversionConfigs(c *gin.Context) {
	var configs []ConversionConfig
	if err := db.Where("is_active = ?", true).Find(&configs).Error; err != nil {
		logger.Errorf("Failed to get conversion configs: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get conversion configs"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"configs": configs})
}

// 内容提取
func extractContent(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		DocumentID     string `json:"document_id" binding:"required"`
		ExtractionType string `json:"extraction_type" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 创建提取任务
	extraction := DocumentExtraction{
		ID:             uuid.New().String(),
		UserID:         userID,
		DocumentID:     req.DocumentID,
		ExtractionType: req.ExtractionType,
		Status:         ProcessingStatusPending,
	}

	if err := db.Create(&extraction).Error; err != nil {
		logger.Errorf("Failed to create extraction: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create extraction"})
		return
	}

	// 异步执行提取
	go extractContentAsync(&extraction)

	c.JSON(http.StatusCreated, gin.H{
		"message":    "Content extraction started",
		"extraction": extraction,
	})
}

// 获取提取结果
func getExtraction(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	extractionID := c.Param("id")
	if extractionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Extraction ID is required"})
		return
	}

	var extraction DocumentExtraction
	if err := db.Where("id = ? AND user_id = ?", extractionID, userID).First(&extraction).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Extraction not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"extraction": extraction})
}

// 获取结构化数据
func getStructuredData(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	extractionID := c.Param("id")
	if extractionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Extraction ID is required"})
		return
	}

	var extraction DocumentExtraction
	if err := db.Where("id = ? AND user_id = ?", extractionID, userID).First(&extraction).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Extraction not found"})
		return
	}

	if extraction.Status != ProcessingStatusCompleted {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Extraction not completed"})
		return
	}

	var structuredData map[string]interface{}
	if err := json.Unmarshal([]byte(extraction.StructuredData), &structuredData); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse structured data"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"structured_data": structuredData})
}

// OCR识别
func performOCR(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		DocumentID  string `json:"document_id" binding:"required"`
		ImageFileID string `json:"image_file_id" binding:"required"`
		Language    string `json:"language"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Language == "" {
		req.Language = "en"
	}

	// 创建OCR任务
	ocrResult := OCRResult{
		ID:         uuid.New().String(),
		UserID:     userID,
		DocumentID: req.DocumentID,
		ImageFileID: req.ImageFileID,
		Language:   req.Language,
		Status:     ProcessingStatusPending,
	}

	if err := db.Create(&ocrResult).Error; err != nil {
		logger.Errorf("Failed to create OCR task: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create OCR task"})
		return
	}

	// 异步执行OCR
	go performOCRAsync(&ocrResult)

	c.JSON(http.StatusCreated, gin.H{
		"message": "OCR processing started",
		"ocr":     ocrResult,
	})
}

// 获取OCR结果
func getOCRResult(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	ocrID := c.Param("id")
	if ocrID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "OCR ID is required"})
		return
	}

	var ocrResult OCRResult
	if err := db.Where("id = ? AND user_id = ?", ocrID, userID).First(&ocrResult).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "OCR result not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ocr": ocrResult})
}

// 获取支持的语言
func getSupportedLanguages(c *gin.Context) {
	languages := []string{"en", "zh", "ja", "ko", "fr", "de", "es", "it", "pt", "ru"}
	c.JSON(http.StatusOK, gin.H{"languages": languages})
}

// 创建模板
func createTemplate(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		Name            string `json:"name" binding:"required"`
		Description     string `json:"description"`
		DocumentType    string `json:"document_type" binding:"required"`
		Format          string `json:"format" binding:"required"`
		TemplateFileID  string `json:"template_file_id"`
		TemplateContent string `json:"template_content"`
		Variables       string `json:"variables"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	template := DocumentTemplate{
		ID:             uuid.New().String(),
		Name:           req.Name,
		Description:    req.Description,
		DocumentType:   DocumentType(req.DocumentType),
		Format:         DocumentFormat(req.Format),
		TemplateFileID: req.TemplateFileID,
		TemplateContent: req.TemplateContent,
		Variables:      req.Variables,
		IsActive:       true,
	}

	if err := db.Create(&template).Error; err != nil {
		logger.Errorf("Failed to create template: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create template"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":  "Template created successfully",
		"template": template,
	})
}

// 获取模板列表
func listTemplates(c *gin.Context) {
	var templates []DocumentTemplate
	query := db.Where("is_active = ?", true)
	
	if docType := c.Query("document_type"); docType != "" {
		query = query.Where("document_type = ?", docType)
	}

	if err := query.Find(&templates).Error; err != nil {
		logger.Errorf("Failed to list templates: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list templates"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"templates": templates})
}

// 获取单个模板
func getTemplate(c *gin.Context) {
	templateID := c.Param("id")
	if templateID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Template ID is required"})
		return
	}

	var template DocumentTemplate
	if err := db.Where("id = ?", templateID).First(&template).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Template not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"template": template})
}

// 更新模板
func updateTemplate(c *gin.Context) {
	templateID := c.Param("id")
	if templateID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Template ID is required"})
		return
	}

	var template DocumentTemplate
	if err := db.Where("id = ?", templateID).First(&template).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Template not found"})
		return
	}

	var req struct {
		Name            string `json:"name"`
		Description     string `json:"description"`
		TemplateContent string `json:"template_content"`
		Variables       string `json:"variables"`
		IsActive        *bool  `json:"is_active"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 更新字段
	if req.Name != "" {
		template.Name = req.Name
	}
	if req.Description != "" {
		template.Description = req.Description
	}
	if req.TemplateContent != "" {
		template.TemplateContent = req.TemplateContent
	}
	if req.Variables != "" {
		template.Variables = req.Variables
	}
	if req.IsActive != nil {
		template.IsActive = *req.IsActive
	}

	if err := db.Save(&template).Error; err != nil {
		logger.Errorf("Failed to update template: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update template"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":  "Template updated successfully",
		"template": template,
	})
}

// 删除模板
func deleteTemplate(c *gin.Context) {
	templateID := c.Param("id")
	if templateID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Template ID is required"})
		return
	}

	if err := db.Where("id = ?", templateID).Delete(&DocumentTemplate{}).Error; err != nil {
		logger.Errorf("Failed to delete template: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete template"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Template deleted successfully"})
}

// 获取处理统计
func getProcessingStats(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	days, _ := strconv.Atoi(c.Query("days"))
	if days == 0 {
		days = 7
	}

	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)

	var stats []ProcessingStats
	if err := db.Where("user_id = ? AND date BETWEEN ? AND ?", 
		userID, startDate, endDate).Order("date ASC").Find(&stats).Error; err != nil {
		logger.Errorf("Failed to get processing stats: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get processing stats"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"start_date": startDate.Format("2006-01-02"),
		"end_date":   endDate.Format("2006-01-02"),
		"stats":      stats,
	})
}

// 获取统计摘要
func getStatsSummary(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var summary struct {
		TotalTasks     int64 `json:"total_tasks"`
		CompletedTasks int64 `json:"completed_tasks"`
		FailedTasks    int64 `json:"failed_tasks"`
		ProcessingTasks int64 `json:"processing_tasks"`
		AvgProcessingTime float64 `json:"avg_processing_time"`
	}

	// 获取任务统计
	db.Model(&DocumentTask{}).Where("user_id = ?", userID).Count(&summary.TotalTasks)
	db.Model(&DocumentTask{}).Where("user_id = ? AND status = ?", userID, ProcessingStatusCompleted).Count(&summary.CompletedTasks)
	db.Model(&DocumentTask{}).Where("user_id = ? AND status = ?", userID, ProcessingStatusFailed).Count(&summary.FailedTasks)
	db.Model(&DocumentTask{}).Where("user_id = ? AND status = ?", userID, ProcessingStatusProcessing).Count(&summary.ProcessingTasks)

	c.JSON(http.StatusOK, gin.H{"summary": summary})
}

// 异步处理任务
func processTask(task *DocumentTask) {
	startTime := time.Now()
	task.Status = ProcessingStatusProcessing
	task.StartedAt = &startTime
	db.Save(task)

	// 模拟处理过程
	time.Sleep(2 * time.Second)
	
	// 更新进度
	for i := 10; i <= 100; i += 10 {
		task.Progress = i
		db.Save(task)
		time.Sleep(500 * time.Millisecond)
	}

	// 完成任务
	completedTime := time.Now()
	task.Status = ProcessingStatusCompleted
	task.CompletedAt = &completedTime
	db.Save(task)

	logger.Infof("Task %s completed", task.ID)
}

// 异步文档转换
func convertDocumentAsync(task *DocumentTask) {
	startTime := time.Now()
	task.Status = ProcessingStatusProcessing
	task.StartedAt = &startTime
	db.Save(task)

	// 模拟转换过程
	time.Sleep(3 * time.Second)
	
	// 生成目标文件ID
	task.TargetFileID = uuid.New().String()
	
	// 完成转换
	completedTime := time.Now()
	task.Status = ProcessingStatusCompleted
	task.CompletedAt = &completedTime
	db.Save(task)

	logger.Infof("Document conversion %s completed", task.ID)
}

// 异步内容提取
func extractContentAsync(extraction *DocumentExtraction) {
	// 模拟提取过程
	time.Sleep(2 * time.Second)
	
	extraction.Content = "Extracted content from document..."
	extraction.StructuredData = `{"name": "John Doe", "email": "john@example.com", "phone": "123-456-7890"}`
	extraction.Confidence = 0.95
	extraction.Status = ProcessingStatusCompleted
	db.Save(extraction)

	logger.Infof("Content extraction %s completed", extraction.ID)
}

// 异步OCR识别
func performOCRAsync(ocrResult *OCRResult) {
	startTime := time.Now()
	ocrResult.Status = ProcessingStatusProcessing
	db.Save(ocrResult)

	// 模拟OCR过程
	time.Sleep(5 * time.Second)
	
	ocrResult.TextContent = "OCR recognized text content..."
	ocrResult.Confidence = 0.88
	ocrResult.Status = ProcessingStatusCompleted
	ocrResult.ProcessingTime = time.Since(startTime).Milliseconds()
	db.Save(ocrResult)

	logger.Infof("OCR processing %s completed", ocrResult.ID)
}
