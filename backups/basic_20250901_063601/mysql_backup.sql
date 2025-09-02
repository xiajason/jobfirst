-- MySQL dump 10.13  Distrib 8.0.43, for Linux (aarch64)
--
-- Host: localhost    Database: jobfirst
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
-- Table structure for table `blockchain_certificates`
--

DROP TABLE IF EXISTS `blockchain_certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blockchain_certificates` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` longtext NOT NULL,
  `description` text,
  `content` text,
  `hash` varchar(66) DEFAULT NULL,
  `blockchain_type` varchar(20) NOT NULL,
  `transaction_hash` varchar(66) DEFAULT NULL,
  `block_number` bigint unsigned DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `gas_used` bigint unsigned DEFAULT NULL,
  `gas_price` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_blockchain_certificates_hash` (`hash`),
  KEY `idx_blockchain_certificates_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blockchain_certificates`
--

LOCK TABLES `blockchain_certificates` WRITE;
/*!40000 ALTER TABLE `blockchain_certificates` DISABLE KEYS */;
/*!40000 ALTER TABLE `blockchain_certificates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `blockchain_configs`
--

DROP TABLE IF EXISTS `blockchain_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blockchain_configs` (
  `id` varchar(36) NOT NULL,
  `blockchain_type` varchar(20) NOT NULL,
  `network_name` longtext NOT NULL,
  `rpc_url` varchar(200) NOT NULL,
  `chain_id` bigint unsigned NOT NULL,
  `currency_symbol` varchar(10) DEFAULT NULL,
  `explorer_url` varchar(200) DEFAULT NULL,
  `gas_limit` bigint unsigned DEFAULT '21000',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_blockchain_configs_blockchain_type` (`blockchain_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blockchain_configs`
--

LOCK TABLES `blockchain_configs` WRITE;
/*!40000 ALTER TABLE `blockchain_configs` DISABLE KEYS */;
/*!40000 ALTER TABLE `blockchain_configs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `blockchain_transactions`
--

DROP TABLE IF EXISTS `blockchain_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blockchain_transactions` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `type` varchar(50) NOT NULL,
  `transaction_hash` varchar(66) DEFAULT NULL,
  `blockchain_type` varchar(20) NOT NULL,
  `from_address` varchar(42) DEFAULT NULL,
  `to_address` varchar(42) DEFAULT NULL,
  `value` varchar(50) DEFAULT NULL,
  `gas_used` bigint unsigned DEFAULT NULL,
  `gas_price` bigint unsigned DEFAULT NULL,
  `block_number` bigint unsigned DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `error` text,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_blockchain_transactions_transaction_hash` (`transaction_hash`),
  KEY `idx_blockchain_transactions_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blockchain_transactions`
--

LOCK TABLES `blockchain_transactions` WRITE;
/*!40000 ALTER TABLE `blockchain_transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `blockchain_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `files`
--

DROP TABLE IF EXISTS `files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `files` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `filename` varchar(255) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_size` bigint NOT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `file_type` enum('image','document','video','other') NOT NULL,
  `status` enum('uploading','completed','failed','deleted') DEFAULT 'uploading',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_files_user_id` (`user_id`),
  KEY `idx_files_status` (`status`),
  CONSTRAINT `files_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `files`
--

LOCK TABLES `files` WRITE;
/*!40000 ALTER TABLE `files` DISABLE KEYS */;
/*!40000 ALTER TABLE `files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'èŒä½æ ‡é¢˜',
  `company_id` bigint unsigned DEFAULT NULL COMMENT 'å…¬å¸ID',
  `company_name` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'å…¬å¸åç§°',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT 'èŒä½æè¿°',
  `requirements` json DEFAULT NULL COMMENT 'èŒä½è¦æ±‚',
  `salary_min` int DEFAULT NULL COMMENT 'æœ€ä½Žè–ªèµ„',
  `salary_max` int DEFAULT NULL COMMENT 'æœ€é«˜è–ªèµ„',
  `salary_type` enum('monthly','yearly','hourly') COLLATE utf8mb4_unicode_ci DEFAULT 'monthly' COMMENT 'è–ªèµ„ç±»åž‹',
  `location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'å·¥ä½œåœ°ç‚¹',
  `job_type` enum('full_time','part_time','internship','contract') COLLATE utf8mb4_unicode_ci DEFAULT 'full_time' COMMENT 'å·¥ä½œç±»åž‹',
  `experience_level` enum('entry','junior','mid','senior','lead') COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ç»éªŒè¦æ±‚',
  `education_level` enum('high_school','college','bachelor','master','phd') COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'å­¦åŽ†è¦æ±‚',
  `skills` json DEFAULT NULL COMMENT 'æŠ€èƒ½è¦æ±‚',
  `benefits` json DEFAULT NULL COMMENT 'ç¦åˆ©å¾…é‡',
  `status` enum('active','closed','draft') COLLATE utf8mb4_unicode_ci DEFAULT 'active' COMMENT 'èŒä½çŠ¶æ€',
  `view_count` int DEFAULT '0' COMMENT 'æµè§ˆæ¬¡æ•°',
  `application_count` int DEFAULT '0' COMMENT 'ç”³è¯·æ¬¡æ•°',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_location` (`location`),
  KEY `idx_status` (`status`),
  KEY `idx_salary_min` (`salary_min`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='èŒä½è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `point_records`
--

DROP TABLE IF EXISTS `point_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `point_records` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `points` int NOT NULL,
  `type` enum('earn','spend') NOT NULL,
  `reason` varchar(100) NOT NULL,
  `description` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_point_records_user_id` (`user_id`),
  CONSTRAINT `point_records_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_records`
--

LOCK TABLES `point_records` WRITE;
/*!40000 ALTER TABLE `point_records` DISABLE KEYS */;
INSERT INTO `point_records` VALUES (1,1,100,'earn','register','æ–°ç”¨æˆ·æ³¨å†Œå¥–åŠ±','2025-08-30 04:45:14'),(2,1,50,'earn','create_resume','åˆ›å»ºç®€åŽ†å¥–åŠ±','2025-08-30 04:45:14'),(3,1,20,'earn','share_resume','åˆ†äº«ç®€åŽ†å¥–åŠ±','2025-08-30 04:45:14'),(4,1,-10,'spend','download_template','ä¸‹è½½ä»˜è´¹æ¨¡æ¿','2025-08-30 04:45:14'),(5,2,100,'earn','register','æ–°ç”¨æˆ·æ³¨å†Œå¥–åŠ±','2025-08-30 04:45:14'),(6,2,50,'earn','create_resume','åˆ›å»ºç®€åŽ†å¥–åŠ±','2025-08-30 04:45:14'),(7,2,-10,'spend','download_template','ä¸‹è½½ä»˜è´¹æ¨¡æ¿','2025-08-30 04:45:14'),(8,3,100,'earn','register','æ–°ç”¨æˆ·æ³¨å†Œå¥–åŠ±','2025-08-30 04:45:14'),(9,3,50,'earn','create_resume','åˆ›å»ºç®€åŽ†å¥–åŠ±','2025-08-30 04:45:14'),(10,4,1000,'earn','admin_bonus','ç®¡ç†å‘˜å¥–åŠ±','2025-08-30 04:45:14');
/*!40000 ALTER TABLE `point_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `points`
--

DROP TABLE IF EXISTS `points`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `points` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `points` int DEFAULT '0',
  `earned_points` int DEFAULT '0',
  `spent_points` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_points_user_id` (`user_id`),
  CONSTRAINT `points_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `points`
--

LOCK TABLES `points` WRITE;
/*!40000 ALTER TABLE `points` DISABLE KEYS */;
INSERT INTO `points` VALUES (1,1,850,1000,150,'2025-08-30 04:45:14','2025-08-30 04:45:14'),(2,2,420,500,80,'2025-08-30 04:45:14','2025-08-30 04:45:14'),(3,3,200,300,100,'2025-08-30 04:45:14','2025-08-30 04:45:14'),(4,4,1000,1000,0,'2025-08-30 04:45:14','2025-08-30 04:45:14');
/*!40000 ALTER TABLE `points` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `points_transaction_histories`
--

DROP TABLE IF EXISTS `points_transaction_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `points_transaction_histories` (
  `transaction_history_id` varchar(36) NOT NULL,
  `from_user_id` varchar(50) NOT NULL,
  `from_user_source` bigint NOT NULL,
  `to_user_id` varchar(50) NOT NULL,
  `to_user_source` bigint NOT NULL,
  `transaction_point` bigint NOT NULL,
  `transaction_code` bigint NOT NULL,
  `transaction_content` text,
  `create_time` datetime(3) NOT NULL,
  `transaction_hash` varchar(66) DEFAULT NULL,
  `block_number` bigint unsigned DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `blockchain_type` varchar(20) DEFAULT 'tencent',
  PRIMARY KEY (`transaction_history_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `points_transaction_histories`
--

LOCK TABLES `points_transaction_histories` WRITE;
/*!40000 ALTER TABLE `points_transaction_histories` DISABLE KEYS */;
/*!40000 ALTER TABLE `points_transaction_histories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resume_banners`
--

DROP TABLE IF EXISTS `resume_banners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resume_banners` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(100) NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `sort` bigint DEFAULT '0',
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resume_banners`
--

LOCK TABLES `resume_banners` WRITE;
/*!40000 ALTER TABLE `resume_banners` DISABLE KEYS */;
INSERT INTO `resume_banners` VALUES (1,'æ–°ç”¨æˆ·æ³¨å†Œé€ç§¯åˆ†','https://via.placeholder.com/800x300','/pages/register/register',1,'active','2025-08-30 04:45:14.000','2025-08-30 04:45:14.000'),(2,'ç²¾é€‰ç®€åŽ†æ¨¡æ¿','https://via.placeholder.com/800x300','/pages/templates/templates',2,'active','2025-08-30 04:45:14.000','2025-08-30 04:45:14.000'),(3,'ç®€åŽ†ä¼˜åŒ–æœåŠ¡','https://via.placeholder.com/800x300','/pages/services/services',3,'active','2025-08-30 04:45:14.000','2025-08-30 04:45:14.000');
/*!40000 ALTER TABLE `resume_banners` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resume_templates`
--

DROP TABLE IF EXISTS `resume_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resume_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` text,
  `preview_url` varchar(255) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resume_templates`
--

LOCK TABLES `resume_templates` WRITE;
/*!40000 ALTER TABLE `resume_templates` DISABLE KEYS */;
/*!40000 ALTER TABLE `resume_templates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resumes`
--

DROP TABLE IF EXISTS `resumes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resumes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `title` varchar(100) NOT NULL,
  `content` text,
  `status` enum('draft','published','archived') DEFAULT 'draft',
  `template_id` bigint unsigned DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_resumes_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resumes`
--

LOCK TABLES `resumes` WRITE;
/*!40000 ALTER TABLE `resumes` DISABLE KEYS */;
INSERT INTO `resumes` VALUES (1,1,'å¼ ä¸‰çš„ç®€åŽ†','{\"basic_info\": {\"name\": \"å¼ ä¸‰\", \"phone\": \"13800138001\", \"email\": \"zhangsan@example.com\", \"address\": \"åŒ—äº¬å¸‚æœé˜³åŒº\"}, \"experience\": [{\"company\": \"è…¾è®¯ç§‘æŠ€\", \"position\": \"é«˜çº§å·¥ç¨‹å¸ˆ\", \"duration\": \"2020-2023\", \"description\": \"è´Ÿè´£å¾®ä¿¡å°ç¨‹åºå¼€å‘\"}], \"education\": [{\"school\": \"æ¸…åŽå¤§å­¦\", \"major\": \"è®¡ç®—æœºç§‘å­¦\", \"degree\": \"æœ¬ç§‘\", \"graduation\": \"2020\"}], \"skills\": [\"JavaScript\", \"Go\", \"MySQL\", \"Redis\"]}','published',1,'2025-08-30 04:45:14.000','2025-08-30 04:45:14.000',NULL),(2,1,'å¼ ä¸‰çš„å¤‡ç”¨ç®€åŽ†','{\"basic_info\": {\"name\": \"å¼ ä¸‰\", \"phone\": \"13800138001\", \"email\": \"zhangsan@example.com\", \"address\": \"åŒ—äº¬å¸‚æœé˜³åŒº\"}, \"experience\": [{\"company\": \"é˜¿é‡Œå·´å·´\", \"position\": \"å‰ç«¯å·¥ç¨‹å¸ˆ\", \"duration\": \"2018-2020\", \"description\": \"è´Ÿè´£æ·˜å®å‰ç«¯å¼€å‘\"}], \"education\": [{\"school\": \"æ¸…åŽå¤§å­¦\", \"major\": \"è®¡ç®—æœºç§‘å­¦\", \"degree\": \"æœ¬ç§‘\", \"graduation\": \"2020\"}], \"skills\": [\"Vue.js\", \"React\", \"Node.js\"]}','draft',2,'2025-08-30 04:45:14.000','2025-08-30 04:45:14.000',NULL),(3,2,'æŽå››çš„ç®€åŽ†','{\"basic_info\": {\"name\": \"æŽå››\", \"phone\": \"13800138002\", \"email\": \"lisi@example.com\", \"address\": \"ä¸Šæµ·å¸‚æµ¦ä¸œæ–°åŒº\"}, \"experience\": [{\"company\": \"å­—èŠ‚è·³åŠ¨\", \"position\": \"äº§å“ç»ç†\", \"duration\": \"2021-2023\", \"description\": \"è´Ÿè´£æŠ–éŸ³äº§å“è®¾è®¡\"}], \"education\": [{\"school\": \"å¤æ—¦å¤§å­¦\", \"major\": \"å·¥å•†ç®¡ç†\", \"degree\": \"ç¡•å£«\", \"graduation\": \"2021\"}], \"skills\": [\"äº§å“è®¾è®¡\", \"æ•°æ®åˆ†æž\", \"é¡¹ç›®ç®¡ç†\"]}','published',1,'2025-08-30 04:45:14.000','2025-08-30 04:45:14.000',NULL),(4,3,'çŽ‹äº”çš„ç®€åŽ†','{\"basic_info\": {\"name\": \"çŽ‹äº”\", \"phone\": \"13800138003\", \"email\": \"wangwu@example.com\", \"address\": \"æ·±åœ³å¸‚å—å±±åŒº\"}, \"experience\": [{\"company\": \"åŽä¸º\", \"position\": \"ç¡¬ä»¶å·¥ç¨‹å¸ˆ\", \"duration\": \"2019-2023\", \"description\": \"è´Ÿè´£æ‰‹æœºç¡¬ä»¶è®¾è®¡\"}], \"education\": [{\"school\": \"åŽå—ç†å·¥å¤§å­¦\", \"major\": \"ç”µå­å·¥ç¨‹\", \"degree\": \"æœ¬ç§‘\", \"graduation\": \"2019\"}], \"skills\": [\"ç”µè·¯è®¾è®¡\", \"PCBè®¾è®¡\", \"åµŒå…¥å¼å¼€å‘\"]}','published',3,'2025-08-30 04:45:14.000','2025-08-30 04:45:14.000',NULL);
/*!40000 ALTER TABLE `resumes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `smart_contracts`
--

DROP TABLE IF EXISTS `smart_contracts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `smart_contracts` (
  `id` varchar(36) NOT NULL,
  `name` longtext NOT NULL,
  `address` varchar(42) NOT NULL,
  `blockchain_type` varchar(20) NOT NULL,
  `abi` text,
  `bytecode` text,
  `version` varchar(20) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_smart_contracts_address` (`address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `smart_contracts`
--

LOCK TABLES `smart_contracts` WRITE;
/*!40000 ALTER TABLE `smart_contracts` DISABLE KEYS */;
/*!40000 ALTER TABLE `smart_contracts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statistics`
--

DROP TABLE IF EXISTS `statistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `statistics` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL COMMENT 'ç»Ÿè®¡æ—¥æœŸ',
  `user_count` int DEFAULT '0' COMMENT 'ç”¨æˆ·æ•°é‡',
  `resume_count` int DEFAULT '0' COMMENT 'ç®€åŽ†æ•°é‡',
  `job_count` int DEFAULT '0' COMMENT 'èŒä½æ•°é‡',
  `application_count` int DEFAULT '0' COMMENT 'ç”³è¯·æ•°é‡',
  `view_count` int DEFAULT '0' COMMENT 'æµè§ˆæ¬¡æ•°',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_date` (`date`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç»Ÿè®¡æ•°æ®è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statistics`
--

LOCK TABLES `statistics` WRITE;
/*!40000 ALTER TABLE `statistics` DISABLE KEYS */;
/*!40000 ALTER TABLE `statistics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statistics_events`
--

DROP TABLE IF EXISTS `statistics_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `statistics_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `event_type` varchar(50) NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `event_data` json DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_event_type` (`event_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statistics_events`
--

LOCK TABLES `statistics_events` WRITE;
/*!40000 ALTER TABLE `statistics_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `statistics_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_behaviors`
--

DROP TABLE IF EXISTS `user_behaviors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_behaviors` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `action` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'è¡Œä¸ºç±»åž‹',
  `target_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ç›®æ ‡ç±»åž‹',
  `target_id` bigint unsigned DEFAULT NULL COMMENT 'ç›®æ ‡ID',
  `metadata` json DEFAULT NULL COMMENT 'å…ƒæ•°æ®',
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IPåœ°å€',
  `user_agent` text COLLATE utf8mb4_unicode_ci COMMENT 'ç”¨æˆ·ä»£ç†',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_action` (`action`),
  KEY `idx_target` (`target_type`,`target_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `user_behaviors_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç”¨æˆ·è¡Œä¸ºè¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_behaviors`
--

LOCK TABLES `user_behaviors` WRITE;
/*!40000 ALTER TABLE `user_behaviors` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_behaviors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_profiles`
--

DROP TABLE IF EXISTS `user_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_profiles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `education_level` enum('high_school','college','bachelor','master','phd') COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'å­¦åŽ†',
  `work_experience` int DEFAULT NULL COMMENT 'å·¥ä½œå¹´é™',
  `current_position` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'å½“å‰èŒä½',
  `expected_salary_min` int DEFAULT NULL COMMENT 'æœŸæœ›è–ªèµ„ä¸‹é™',
  `expected_salary_max` int DEFAULT NULL COMMENT 'æœŸæœ›è–ªèµ„ä¸Šé™',
  `skills` json DEFAULT NULL COMMENT 'æŠ€èƒ½æ ‡ç­¾',
  `self_introduction` text COLLATE utf8mb4_unicode_ci COMMENT 'è‡ªæˆ‘ä»‹ç»',
  `resume_count` int DEFAULT '0' COMMENT 'ç®€åŽ†æ•°é‡',
  `application_count` int DEFAULT '0' COMMENT 'æŠ•é€’æ¬¡æ•°',
  `favorite_count` int DEFAULT '0' COMMENT 'æ”¶è—æ•°é‡',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_education_level` (`education_level`),
  KEY `idx_work_experience` (`work_experience`),
  CONSTRAINT `user_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ç”¨æˆ·è¯¦ç»†èµ„æ–™è¡¨';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_profiles`
--

LOCK TABLES `user_profiles` WRITE;
/*!40000 ALTER TABLE `user_profiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `avatar_url` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','banned') DEFAULT 'active',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_users_email` (`email`),
  KEY `idx_users_username` (`username`),
  KEY `idx_users_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'testuser1','test1@example.com','$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','13800138001','https://via.placeholder.com/150','active','2025-08-30 04:42:41.000','2025-08-30 04:42:41.000',NULL),(2,'testuser2','test2@example.com','$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','13800138002','https://via.placeholder.com/150','active','2025-08-30 04:42:41.000','2025-08-30 04:42:41.000',NULL),(3,'testuser3','test3@example.com','$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','13800138003','https://via.placeholder.com/150','active','2025-08-30 04:42:41.000','2025-08-30 04:42:41.000',NULL),(4,'admin','admin@jobfirst.com','$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','13800138000','https://via.placeholder.com/150','active','2025-08-30 04:42:41.000','2025-08-30 04:42:41.000',NULL),(6,'testuser','test@example.com','testpass123','','','active','2025-08-31 14:01:50.285','2025-08-31 14:01:50.285',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wallets`
--

DROP TABLE IF EXISTS `wallets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallets` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `address` varchar(42) NOT NULL,
  `private_key` varchar(66) NOT NULL,
  `blockchain_type` varchar(20) NOT NULL,
  `balance` varchar(50) DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_wallets_user_id` (`user_id`),
  UNIQUE KEY `idx_wallets_address` (`address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wallets`
--

LOCK TABLES `wallets` WRITE;
/*!40000 ALTER TABLE `wallets` DISABLE KEYS */;
/*!40000 ALTER TABLE `wallets` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-08-31 22:36:02
