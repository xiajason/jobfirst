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
-- Table structure for table `file_access_logs`
--

DROP TABLE IF EXISTS `file_access_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `file_access_logs` (
  `id` varchar(36) NOT NULL,
  `file_id` varchar(36) NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `action` varchar(20) NOT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` text,
  `referer` varchar(500) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_file_access_logs_file_id` (`file_id`),
  KEY `idx_file_access_logs_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file_access_logs`
--

LOCK TABLES `file_access_logs` WRITE;
/*!40000 ALTER TABLE `file_access_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `file_access_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `file_process_tasks`
--

DROP TABLE IF EXISTS `file_process_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `file_process_tasks` (
  `id` varchar(36) NOT NULL,
  `file_id` varchar(36) NOT NULL,
  `task_type` varchar(50) NOT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `progress` bigint DEFAULT '0',
  `result` json DEFAULT NULL,
  `error` text,
  `started_at` datetime(3) DEFAULT NULL,
  `completed_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_file_process_tasks_file_id` (`file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file_process_tasks`
--

LOCK TABLES `file_process_tasks` WRITE;
/*!40000 ALTER TABLE `file_process_tasks` DISABLE KEYS */;
/*!40000 ALTER TABLE `file_process_tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `file_records`
--

DROP TABLE IF EXISTS `file_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `file_records` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `file_name` longtext NOT NULL,
  `original_name` longtext NOT NULL,
  `file_type` varchar(20) NOT NULL,
  `mime_type` varchar(100) NOT NULL,
  `size` bigint NOT NULL,
  `extension` varchar(20) DEFAULT NULL,
  `storage_type` varchar(20) NOT NULL,
  `storage_path` varchar(500) NOT NULL,
  `storage_url` varchar(500) DEFAULT NULL,
  `md5_hash` varchar(32) DEFAULT NULL,
  `sha256_hash` varchar(64) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'uploading',
  `is_public` tinyint(1) DEFAULT '0',
  `download_count` bigint DEFAULT '0',
  `view_count` bigint DEFAULT '0',
  `metadata` json DEFAULT NULL,
  `expires_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_file_records_md5_hash` (`md5_hash`),
  KEY `idx_file_records_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file_records`
--

LOCK TABLES `file_records` WRITE;
/*!40000 ALTER TABLE `file_records` DISABLE KEYS */;
/*!40000 ALTER TABLE `file_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `file_shares`
--

DROP TABLE IF EXISTS `file_shares`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `file_shares` (
  `id` varchar(36) NOT NULL,
  `file_id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `share_token` varchar(64) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `is_public` tinyint(1) DEFAULT '0',
  `max_downloads` bigint DEFAULT '0',
  `download_count` bigint DEFAULT '0',
  `expires_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_file_shares_share_token` (`share_token`),
  KEY `idx_file_shares_file_id` (`file_id`),
  KEY `idx_file_shares_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file_shares`
--

LOCK TABLES `file_shares` WRITE;
/*!40000 ALTER TABLE `file_shares` DISABLE KEYS */;
/*!40000 ALTER TABLE `file_shares` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `file_tags`
--

DROP TABLE IF EXISTS `file_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `file_tags` (
  `id` varchar(36) NOT NULL,
  `file_id` varchar(36) NOT NULL,
  `tag_name` varchar(50) NOT NULL,
  `tag_value` varchar(200) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_file_tags_file_id` (`file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file_tags`
--

LOCK TABLES `file_tags` WRITE;
/*!40000 ALTER TABLE `file_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `file_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `file_versions`
--

DROP TABLE IF EXISTS `file_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `file_versions` (
  `id` varchar(36) NOT NULL,
  `file_id` varchar(36) NOT NULL,
  `version` bigint NOT NULL,
  `file_name` longtext NOT NULL,
  `size` bigint NOT NULL,
  `storage_path` varchar(500) NOT NULL,
  `md5_hash` varchar(32) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'uploaded',
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_file_versions_file_id` (`file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file_versions`
--

LOCK TABLES `file_versions` WRITE;
/*!40000 ALTER TABLE `file_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `file_versions` ENABLE KEYS */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_records`
--

LOCK TABLES `point_records` WRITE;
/*!40000 ALTER TABLE `point_records` DISABLE KEYS */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `points`
--

LOCK TABLES `points` WRITE;
/*!40000 ALTER TABLE `points` DISABLE KEYS */;
/*!40000 ALTER TABLE `points` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `points_records`
--

DROP TABLE IF EXISTS `points_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `points_records` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `type` varchar(20) NOT NULL,
  `source` varchar(50) NOT NULL,
  `points` bigint NOT NULL,
  `description` text,
  `reference_id` varchar(100) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_points_records_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `points_records`
--

LOCK TABLES `points_records` WRITE;
/*!40000 ALTER TABLE `points_records` DISABLE KEYS */;
/*!40000 ALTER TABLE `points_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `points_rules`
--

DROP TABLE IF EXISTS `points_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `points_rules` (
  `id` varchar(36) NOT NULL,
  `name` longtext NOT NULL,
  `source` varchar(50) NOT NULL,
  `points` bigint NOT NULL,
  `description` text,
  `is_active` tinyint(1) DEFAULT '1',
  `daily_limit` bigint DEFAULT '0',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_points_rules_source` (`source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `points_rules`
--

LOCK TABLES `points_rules` WRITE;
/*!40000 ALTER TABLE `points_rules` DISABLE KEYS */;
/*!40000 ALTER TABLE `points_rules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `real_time_stats`
--

DROP TABLE IF EXISTS `real_time_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `real_time_stats` (
  `id` varchar(36) NOT NULL,
  `type` varchar(50) NOT NULL,
  `value` bigint DEFAULT '0',
  `last_updated` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_real_time_stats_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `real_time_stats`
--

LOCK TABLES `real_time_stats` WRITE;
/*!40000 ALTER TABLE `real_time_stats` DISABLE KEYS */;
/*!40000 ALTER TABLE `real_time_stats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resume_banners`
--

DROP TABLE IF EXISTS `resume_banners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resume_banners` (
  `id` varchar(36) NOT NULL,
  `title` longtext NOT NULL,
  `content` text,
  `image_url` longtext,
  `link_url` longtext,
  `order` bigint DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `start_time` datetime(3) DEFAULT NULL,
  `end_time` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resume_banners`
--

LOCK TABLES `resume_banners` WRITE;
/*!40000 ALTER TABLE `resume_banners` DISABLE KEYS */;
/*!40000 ALTER TABLE `resume_banners` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resume_templates`
--

DROP TABLE IF EXISTS `resume_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resume_templates` (
  `id` varchar(36) NOT NULL,
  `name` longtext NOT NULL,
  `description` text,
  `template_data` json NOT NULL,
  `preview_image` varchar(255) DEFAULT NULL,
  `category` varchar(50) DEFAULT NULL,
  `is_free` tinyint(1) DEFAULT '1',
  `price` double DEFAULT '0',
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `preview_url` longtext,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resume_templates`
--

LOCK TABLES `resume_templates` WRITE;
/*!40000 ALTER TABLE `resume_templates` DISABLE KEYS */;
INSERT INTO `resume_templates` VALUES ('template-001','ç»å…¸å•†åŠ¡æ¨¡æ¿','é€‚åˆå•†åŠ¡äººå£«çš„ç»å…¸ç®€åŽ†æ¨¡æ¿','{\"sections\": [\"basic_info\", \"experience\", \"education\", \"skills\"]}',NULL,'business',1,0,'active','2025-08-29 09:16:59.000','2025-08-29 09:16:59.000',NULL,1),('template-002','åˆ›æ„è®¾è®¡æ¨¡æ¿','é€‚åˆè®¾è®¡å¸ˆçš„åˆ›æ„ç®€åŽ†æ¨¡æ¿','{\"sections\": [\"basic_info\", \"portfolio\", \"experience\", \"skills\"]}',NULL,'creative',1,0,'active','2025-08-29 09:16:59.000','2025-08-29 09:16:59.000',NULL,1),('template-003','æŠ€æœ¯å¼€å‘æ¨¡æ¿','é€‚åˆç¨‹åºå‘˜çš„ä¸“ä¸šç®€åŽ†æ¨¡æ¿','{\"sections\": [\"basic_info\", \"skills\", \"experience\", \"projects\"]}',NULL,'technology',1,0,'active','2025-08-29 09:16:59.000','2025-08-29 09:16:59.000',NULL,1);
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
  `title` longtext NOT NULL,
  `content` text,
  `template_id` varchar(36) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'draft',
  `view_count` bigint DEFAULT '0',
  `download_count` bigint DEFAULT '0',
  `share_count` int DEFAULT '0',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_resumes_user_id` (`user_id`),
  KEY `idx_resumes_status` (`status`),
  KEY `fk_resumes_template` (`template_id`),
  CONSTRAINT `fk_resumes_template` FOREIGN KEY (`template_id`) REFERENCES `resume_templates` (`id`),
  CONSTRAINT `resumes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resumes`
--

LOCK TABLES `resumes` WRITE;
/*!40000 ALTER TABLE `resumes` DISABLE KEYS */;
/*!40000 ALTER TABLE `resumes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statistics`
--

DROP TABLE IF EXISTS `statistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `statistics` (
  `id` varchar(36) NOT NULL,
  `type` varchar(50) NOT NULL,
  `period` varchar(20) NOT NULL,
  `date` datetime(3) NOT NULL,
  `value` bigint DEFAULT '0',
  `user_id` bigint unsigned DEFAULT NULL,
  `reference_id` varchar(100) DEFAULT NULL,
  `metadata` text,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_statistics_user_id` (`user_id`),
  KEY `idx_statistics_type` (`type`),
  KEY `idx_statistics_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
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
-- Table structure for table `statistics_reports`
--

DROP TABLE IF EXISTS `statistics_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `statistics_reports` (
  `id` varchar(36) NOT NULL,
  `name` longtext NOT NULL,
  `type` varchar(50) NOT NULL,
  `period` varchar(20) NOT NULL,
  `start_date` datetime(3) NOT NULL,
  `end_date` datetime(3) NOT NULL,
  `data` text,
  `is_generated` tinyint(1) DEFAULT '0',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statistics_reports`
--

LOCK TABLES `statistics_reports` WRITE;
/*!40000 ALTER TABLE `statistics_reports` DISABLE KEYS */;
/*!40000 ALTER TABLE `statistics_reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `storage_configs`
--

DROP TABLE IF EXISTS `storage_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `storage_configs` (
  `id` varchar(36) NOT NULL,
  `storage_type` varchar(20) NOT NULL,
  `config_name` longtext NOT NULL,
  `config_data` json DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `is_default` tinyint(1) DEFAULT '0',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_storage_configs_storage_type` (`storage_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `storage_configs`
--

LOCK TABLES `storage_configs` WRITE;
/*!40000 ALTER TABLE `storage_configs` DISABLE KEYS */;
/*!40000 ALTER TABLE `storage_configs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `storage_quota`
--

DROP TABLE IF EXISTS `storage_quota`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `storage_quota` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `total_quota` bigint NOT NULL,
  `used_quota` bigint DEFAULT '0',
  `file_count` bigint DEFAULT '0',
  `last_reset_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_storage_quota_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `storage_quota`
--

LOCK TABLES `storage_quota` WRITE;
/*!40000 ALTER TABLE `storage_quota` DISABLE KEYS */;
/*!40000 ALTER TABLE `storage_quota` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_behaviors`
--

DROP TABLE IF EXISTS `user_behaviors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_behaviors` (
  `id` varchar(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `type` varchar(50) NOT NULL,
  `reference_id` varchar(100) DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` text,
  `metadata` text,
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_behaviors_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_behaviors`
--

LOCK TABLES `user_behaviors` WRITE;
/*!40000 ALTER TABLE `user_behaviors` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_behaviors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_points`
--

DROP TABLE IF EXISTS `user_points`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_points` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `points` bigint DEFAULT '0',
  `level` bigint DEFAULT '1',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_points_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_points`
--

LOCK TABLES `user_points` WRITE;
/*!40000 ALTER TABLE `user_points` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_points` ENABLE KEYS */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-08-29 12:24:22
