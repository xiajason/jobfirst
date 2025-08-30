-- MySQL dump 10.13  Distrib 8.0.43, for Linux (aarch64)
--
-- Host: localhost    Database: talent_shared
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activity`
--

DROP TABLE IF EXISTS `activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `activity` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned DEFAULT NULL COMMENT 'ç”¨æˆ·ID',
  `activity_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æ´»åŠ¨ç±»åž‹',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'æ´»åŠ¨æè¿°',
  `metadata` json DEFAULT NULL COMMENT 'å…ƒæ•°æ®',
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IPåœ°å€',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_activity_type` (`activity_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='æ´»åŠ¨è®°å½•è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity`
--

LOCK TABLES `activity` WRITE;
/*!40000 ALTER TABLE `activity` DISABLE KEYS */;
/*!40000 ALTER TABLE `activity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ai_inference_logs`
--

DROP TABLE IF EXISTS `ai_inference_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_inference_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `model_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æ¨¡åž‹åç§°',
  `inference_type` enum('search','recommendation','classification','qa','embedding') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æŽ¨ç†ç±»åž‹',
  `input_data` json DEFAULT NULL COMMENT 'è¾“å…¥æ•°æ®',
  `output_data` json DEFAULT NULL COMMENT 'è¾“å‡ºæ•°æ®',
  `response_time_ms` int DEFAULT NULL COMMENT 'å“åº”æ—¶é—´(æ¯«ç§’)',
  `tokens_used` int DEFAULT NULL COMMENT 'ä½¿ç”¨çš„tokenæ•°',
  `cost_usd` decimal(10,6) DEFAULT NULL COMMENT 'æˆæœ¬(ç¾Žå…ƒ)',
  `user_id` bigint unsigned DEFAULT NULL COMMENT 'ç”¨æˆ·ID',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_model_name` (`model_name`),
  KEY `idx_inference_type` (`inference_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AIæŽ¨ç†æ—¥å¿—è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_inference_logs`
--

LOCK TABLES `ai_inference_logs` WRITE;
/*!40000 ALTER TABLE `ai_inference_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `ai_inference_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ai_models`
--

DROP TABLE IF EXISTS `ai_models`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_models` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `model_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æ¨¡åž‹åç§°',
  `model_type` enum('embedding','classification','recommendation','qa','generation') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æ¨¡åž‹ç±»åž‹',
  `provider` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æä¾›å•†',
  `model_version` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'æ¨¡åž‹ç‰ˆæœ¬',
  `endpoint_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'APIç«¯ç‚¹',
  `api_key_encrypted` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'åŠ å¯†çš„APIå¯†é’¥',
  `is_active` tinyint(1) DEFAULT '1' COMMENT 'æ˜¯å¦æ¿€æ´»',
  `performance_metrics` json DEFAULT NULL COMMENT 'æ€§èƒ½æŒ‡æ ‡',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_model_type` (`model_type`),
  KEY `idx_provider` (`provider`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AIæ¨¡åž‹é…ç½®è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_models`
--

LOCK TABLES `ai_models` WRITE;
/*!40000 ALTER TABLE `ai_models` DISABLE KEYS */;
INSERT INTO `ai_models` VALUES (1,'text-embedding-ada-002','embedding','openai','v1',NULL,NULL,1,NULL,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(2,'gpt-4','generation','openai','v1',NULL,NULL,1,NULL,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(3,'sentence-transformers','embedding','huggingface','v2.2.2',NULL,NULL,1,NULL,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(4,'bert-base-chinese','classification','huggingface','v1',NULL,NULL,1,NULL,'2025-08-27 15:31:43','2025-08-27 15:31:43');
/*!40000 ALTER TABLE `ai_models` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned DEFAULT NULL COMMENT 'ç”¨æˆ·ID',
  `action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æ“ä½œç±»åž‹',
  `resource_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'èµ„æºç±»åž‹',
  `resource_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'èµ„æºID',
  `details` json DEFAULT NULL COMMENT 'è¯¦ç»†ä¿¡æ¯',
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IPåœ°å€',
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'ç”¨æˆ·ä»£ç†',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_action` (`action`),
  KEY `idx_resource_type` (`resource_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='å®¡è®¡æ—¥å¿—è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_logs`
--

LOCK TABLES `audit_logs` WRITE;
/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_management`
--

DROP TABLE IF EXISTS `cache_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_management` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cache_key` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ç¼“å­˜é”®',
  `cache_type` enum('redis','memory','file') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'redis' COMMENT 'ç¼“å­˜ç±»åž‹',
  `data_size_bytes` bigint DEFAULT NULL COMMENT 'æ•°æ®å¤§å°(å­—èŠ‚)',
  `ttl_seconds` int DEFAULT NULL COMMENT 'ç”Ÿå­˜æ—¶é—´(ç§’)',
  `hit_count` int DEFAULT '0' COMMENT 'å‘½ä¸­æ¬¡æ•°',
  `miss_count` int DEFAULT '0' COMMENT 'æœªå‘½ä¸­æ¬¡æ•°',
  `last_accessed` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cache_key` (`cache_key`(255)),
  KEY `idx_cache_type` (`cache_type`),
  KEY `idx_last_accessed` (`last_accessed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç¼“å­˜ç®¡ç†è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_management`
--

LOCK TABLES `cache_management` WRITE;
/*!40000 ALTER TABLE `cache_management` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `geo_locations`
--

DROP TABLE IF EXISTS `geo_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `geo_locations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `subsystem` varchar(100) NOT NULL,
  `region` varchar(100) DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `timezone` varchar(50) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_location` (`subsystem`,`ip_address`),
  KEY `idx_subsystem` (`subsystem`),
  KEY `idx_timestamp` (`timestamp`),
  KEY `idx_ip` (`ip_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `geo_locations`
--

LOCK TABLES `geo_locations` WRITE;
/*!40000 ALTER TABLE `geo_locations` DISABLE KEYS */;
/*!40000 ALTER TABLE `geo_locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `monitoring_metrics`
--

DROP TABLE IF EXISTS `monitoring_metrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `monitoring_metrics` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `metric_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æŒ‡æ ‡åç§°',
  `metric_value` decimal(15,4) NOT NULL COMMENT 'æŒ‡æ ‡å€¼',
  `metric_unit` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'æŒ‡æ ‡å•ä½',
  `service_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'æœåŠ¡åç§°',
  `tags` json DEFAULT NULL COMMENT 'æ ‡ç­¾',
  `timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_metric_name` (`metric_name`),
  KEY `idx_service_name` (`service_name`),
  KEY `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç›‘æŽ§æŒ‡æ ‡è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `monitoring_metrics`
--

LOCK TABLES `monitoring_metrics` WRITE;
/*!40000 ALTER TABLE `monitoring_metrics` DISABLE KEYS */;
/*!40000 ALTER TABLE `monitoring_metrics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_health`
--

DROP TABLE IF EXISTS `service_health`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_health` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `service_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æœåŠ¡åç§°',
  `service_type` enum('database','cache','ai_model','api','monitoring') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æœåŠ¡ç±»åž‹',
  `status` enum('healthy','warning','critical','unknown') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'unknown' COMMENT 'å¥åº·çŠ¶æ€',
  `response_time_ms` int DEFAULT NULL COMMENT 'å“åº”æ—¶é—´(æ¯«ç§’)',
  `error_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'é”™è¯¯ä¿¡æ¯',
  `last_check` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_service_name` (`service_name`),
  KEY `idx_service_type` (`service_type`),
  KEY `idx_status` (`status`),
  KEY `idx_last_check` (`last_check`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='æœåŠ¡å¥åº·çŠ¶æ€è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_health`
--

LOCK TABLES `service_health` WRITE;
/*!40000 ALTER TABLE `service_health` DISABLE KEYS */;
INSERT INTO `service_health` VALUES (1,'neo4j','database','unknown',NULL,NULL,'2025-08-27 15:31:43'),(2,'weaviate','ai_model','unknown',NULL,NULL,'2025-08-27 15:31:43'),(3,'postgres','database','unknown',NULL,NULL,'2025-08-27 15:31:43'),(4,'redis','cache','unknown',NULL,NULL,'2025-08-27 15:31:43'),(5,'elasticsearch','database','unknown',NULL,NULL,'2025-08-27 15:31:43'),(6,'prometheus','monitoring','unknown',NULL,NULL,'2025-08-27 15:31:43'),(7,'grafana','monitoring','unknown',NULL,NULL,'2025-08-27 15:31:43');
/*!40000 ALTER TABLE `service_health` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sync_logs`
--

DROP TABLE IF EXISTS `sync_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sync_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `sync_type` enum('neo4j_to_postgres','postgres_to_weaviate','weaviate_to_elasticsearch') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'åŒæ­¥ç±»åž‹',
  `source_table` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'æºè¡¨',
  `target_table` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ç›®æ ‡è¡¨',
  `records_processed` int DEFAULT '0' COMMENT 'å¤„ç†è®°å½•æ•°',
  `records_success` int DEFAULT '0' COMMENT 'æˆåŠŸè®°å½•æ•°',
  `records_failed` int DEFAULT '0' COMMENT 'å¤±è´¥è®°å½•æ•°',
  `error_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'é”™è¯¯ä¿¡æ¯',
  `started_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'å¼€å§‹æ—¶é—´',
  `completed_at` timestamp NULL DEFAULT NULL COMMENT 'å®Œæˆæ—¶é—´',
  PRIMARY KEY (`id`),
  KEY `idx_sync_type` (`sync_type`),
  KEY `idx_started_at` (`started_at`),
  KEY `idx_completed_at` (`completed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='æ•°æ®åŒæ­¥æ—¥å¿—è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sync_logs`
--

LOCK TABLES `sync_logs` WRITE;
/*!40000 ALTER TABLE `sync_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `sync_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `system_configs`
--

DROP TABLE IF EXISTS `system_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `config_key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'é…ç½®é”®',
  `config_value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'é…ç½®å€¼',
  `config_type` enum('string','number','boolean','json','array') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'string' COMMENT 'é…ç½®ç±»åž‹',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'é…ç½®æè¿°',
  `is_encrypted` tinyint(1) DEFAULT '0' COMMENT 'æ˜¯å¦åŠ å¯†',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_key` (`config_key`),
  KEY `idx_config_key` (`config_key`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç³»ç»Ÿé…ç½®è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `system_configs`
--

LOCK TABLES `system_configs` WRITE;
/*!40000 ALTER TABLE `system_configs` DISABLE KEYS */;
INSERT INTO `system_configs` VALUES (1,'system_name','Talent CRM AI System','string','ç³»ç»Ÿåç§°',0,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(2,'system_version','2.0.0','string','ç³»ç»Ÿç‰ˆæœ¬',0,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(3,'ai_enabled','true','boolean','æ˜¯å¦å¯ç”¨AIåŠŸèƒ½',0,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(4,'max_search_results','100','number','æœ€å¤§æœç´¢ç»“æžœæ•°',0,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(5,'cache_ttl_default','3600','number','é»˜è®¤ç¼“å­˜ç”Ÿå­˜æ—¶é—´(ç§’)',0,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(6,'monitoring_enabled','true','boolean','æ˜¯å¦å¯ç”¨ç›‘æŽ§',0,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(7,'log_level','INFO','string','æ—¥å¿—çº§åˆ«',0,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(8,'api_rate_limit','{\"requests_per_minute\": 100, \"burst_size\": 20}','json','APIé™æµé…ç½®',0,'2025-08-27 15:31:43','2025-08-27 15:31:43');
/*!40000 ALTER TABLE `system_configs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `system_overview`
--

DROP TABLE IF EXISTS `system_overview`;
/*!50001 DROP VIEW IF EXISTS `system_overview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `system_overview` AS SELECT 
 1 AS `table_name`,
 1 AS `record_count`,
 1 AS `last_updated`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `translation_services`
--

DROP TABLE IF EXISTS `translation_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `translation_services` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `service_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æœåŠ¡åç§°',
  `provider` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'æä¾›å•†',
  `api_endpoint` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'APIç«¯ç‚¹',
  `api_key_encrypted` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'åŠ å¯†çš„APIå¯†é’¥',
  `supported_languages` json DEFAULT NULL COMMENT 'æ”¯æŒçš„è¯­è¨€',
  `is_active` tinyint(1) DEFAULT '1' COMMENT 'æ˜¯å¦æ¿€æ´»',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_service_name` (`service_name`),
  KEY `idx_provider` (`provider`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç¿»è¯‘æœåŠ¡è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `translation_services`
--

LOCK TABLES `translation_services` WRITE;
/*!40000 ALTER TABLE `translation_services` DISABLE KEYS */;
INSERT INTO `translation_services` VALUES (1,'google_translate','google',NULL,NULL,'[\"zh\", \"en\", \"ja\", \"ko\"]',1,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(2,'azure_translator','microsoft',NULL,NULL,'[\"zh\", \"en\", \"ja\", \"ko\", \"fr\", \"de\"]',1,'2025-08-27 15:31:43','2025-08-27 15:31:43');
/*!40000 ALTER TABLE `translation_services` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ç”¨æˆ·å',
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'é‚®ç®±',
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'å¯†ç å“ˆå¸Œ',
  `full_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'å…¨å',
  `role` enum('admin','manager','recruiter','viewer') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'viewer' COMMENT 'ç”¨æˆ·è§’è‰²',
  `is_active` tinyint(1) DEFAULT '1' COMMENT 'æ˜¯å¦æ¿€æ´»',
  `last_login` timestamp NULL DEFAULT NULL COMMENT 'æœ€åŽç™»å½•æ—¶é—´',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_username` (`username`),
  KEY `idx_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç”¨æˆ·ç®¡ç†è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin','admin@talentcrm.com','$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8.','ç³»ç»Ÿç®¡ç†å‘˜','admin',1,NULL,'2025-08-27 15:31:43','2025-08-27 15:31:43'),(2,'manager','manager@talentcrm.com','$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8.','æ‹›è˜ç»ç†','manager',1,NULL,'2025-08-27 15:31:43','2025-08-27 15:31:43');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vaults`
--

DROP TABLE IF EXISTS `vaults`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vaults` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ä»“åº“å”¯ä¸€æ ‡è¯†',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ä»“åº“åç§°',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'ä»“åº“æè¿°',
  `owner_id` bigint unsigned DEFAULT NULL COMMENT 'æ‰€æœ‰è€…ID',
  `is_public` tinyint(1) DEFAULT '0' COMMENT 'æ˜¯å¦å…¬å¼€',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner_id` (`owner_id`),
  KEY `idx_is_public` (`is_public`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='æ•°æ®ä»“åº“è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vaults`
--

LOCK TABLES `vaults` WRITE;
/*!40000 ALTER TABLE `vaults` DISABLE KEYS */;
INSERT INTO `vaults` VALUES ('default-vault-001','é»˜è®¤äººæ‰åº“','ç³»ç»Ÿé»˜è®¤çš„äººæ‰æ•°æ®ä»“åº“',NULL,1,'2025-08-27 15:31:43','2025-08-27 15:31:43');
/*!40000 ALTER TABLE `vaults` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `system_overview`
--

/*!50001 DROP VIEW IF EXISTS `system_overview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `system_overview` AS select 'users' AS `table_name`,count(0) AS `record_count`,max(`users`.`created_at`) AS `last_updated` from `users` union all select 'ai_models' AS `table_name`,count(0) AS `record_count`,max(`ai_models`.`created_at`) AS `last_updated` from `ai_models` union all select 'audit_logs' AS `table_name`,count(0) AS `record_count`,max(`audit_logs`.`created_at`) AS `last_updated` from `audit_logs` union all select 'monitoring_metrics' AS `table_name`,count(0) AS `record_count`,max(`monitoring_metrics`.`timestamp`) AS `last_updated` from `monitoring_metrics` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-08-29 12:43:20
