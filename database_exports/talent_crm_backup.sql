-- MySQL dump 10.13  Distrib 9.4.0, for macos15.4 (arm64)
--
-- Host: localhost    Database: talent_crm
-- ------------------------------------------------------
-- Server version	9.4.0

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
-- Table structure for table `certifications`
--

DROP TABLE IF EXISTS `certifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `certifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '认证名称',
  `issuer` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '颁发机构',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '认证描述',
  `validity_period` int DEFAULT NULL COMMENT '有效期(月)',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `certifications`
--

LOCK TABLES `certifications` WRITE;
/*!40000 ALTER TABLE `certifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `certifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `companies`
--

DROP TABLE IF EXISTS `companies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `companies` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '公司名称',
  `industry` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属行业',
  `size` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '公司规模: startup, small, medium, large',
  `location` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '公司地址',
  `website` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '公司网站',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '公司描述',
  `logo_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '公司logo',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `companies`
--

LOCK TABLES `companies` WRITE;
/*!40000 ALTER TABLE `companies` DISABLE KEYS */;
/*!40000 ALTER TABLE `companies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `emotions`
--

DROP TABLE IF EXISTS `emotions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `emotions` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '情感ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '情感名称',
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '情感类型',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `emotions`
--

LOCK TABLES `emotions` WRITE;
/*!40000 ALTER TABLE `emotions` DISABLE KEYS */;
/*!40000 ALTER TABLE `emotions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `files`
--

DROP TABLE IF EXISTS `files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `files` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '文件ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件名',
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '文件路径',
  `mime_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'MIME类型',
  `size` int DEFAULT NULL COMMENT '文件大小',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `files`
--

LOCK TABLES `files` WRITE;
/*!40000 ALTER TABLE `files` DISABLE KEYS */;
/*!40000 ALTER TABLE `files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `genders`
--

DROP TABLE IF EXISTS `genders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `genders` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '性别ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '性别名称',
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '性别类型',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `genders`
--

LOCK TABLES `genders` WRITE;
/*!40000 ALTER TABLE `genders` DISABLE KEYS */;
/*!40000 ALTER TABLE `genders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `industries`
--

DROP TABLE IF EXISTS `industries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `industries` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '行业名称',
  `parent_id` int DEFAULT NULL COMMENT '父行业ID',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '行业描述',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `parent_id` (`parent_id`),
  CONSTRAINT `industries_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `industries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `industries`
--

LOCK TABLES `industries` WRITE;
/*!40000 ALTER TABLE `industries` DISABLE KEYS */;
/*!40000 ALTER TABLE `industries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `life_event_categories`
--

DROP TABLE IF EXISTS `life_event_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `life_event_categories` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '事件分类ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '分类名称',
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '分类类型',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `life_event_categories`
--

LOCK TABLES `life_event_categories` WRITE;
/*!40000 ALTER TABLE `life_event_categories` DISABLE KEYS */;
/*!40000 ALTER TABLE `life_event_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `life_event_participants`
--

DROP TABLE IF EXISTS `life_event_participants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `life_event_participants` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '参与者ID',
  `life_event_id` bigint NOT NULL COMMENT '生活事件ID',
  `poet_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '诗人ID',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `life_event_id` (`life_event_id`),
  KEY `poet_id` (`poet_id`),
  CONSTRAINT `life_event_participants_ibfk_1` FOREIGN KEY (`life_event_id`) REFERENCES `life_events` (`id`),
  CONSTRAINT `life_event_participants_ibfk_2` FOREIGN KEY (`poet_id`) REFERENCES `poets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `life_event_participants`
--

LOCK TABLES `life_event_participants` WRITE;
/*!40000 ALTER TABLE `life_event_participants` DISABLE KEYS */;
/*!40000 ALTER TABLE `life_event_participants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `life_event_types`
--

DROP TABLE IF EXISTS `life_event_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `life_event_types` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '事件类型ID',
  `life_event_category_id` bigint NOT NULL COMMENT '事件分类ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '事件类型名称',
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '事件类型',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `life_event_category_id` (`life_event_category_id`),
  CONSTRAINT `life_event_types_ibfk_1` FOREIGN KEY (`life_event_category_id`) REFERENCES `life_event_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `life_event_types`
--

LOCK TABLES `life_event_types` WRITE;
/*!40000 ALTER TABLE `life_event_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `life_event_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `life_events`
--

DROP TABLE IF EXISTS `life_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `life_events` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '生活事件ID',
  `timeline_event_id` bigint NOT NULL COMMENT '时间线事件ID',
  `life_event_type_id` bigint NOT NULL COMMENT '事件类型ID',
  `emotion_id` bigint DEFAULT NULL COMMENT '情感ID',
  `happened_at` date NOT NULL COMMENT '事件发生日期',
  `collapsed` int NOT NULL COMMENT '是否折叠',
  `summary` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '事件摘要',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '事件描述',
  `costs` int DEFAULT NULL COMMENT '费用',
  `currency_id` bigint DEFAULT NULL COMMENT '货币ID',
  `paid_by_poet_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '支付诗人ID',
  `duration_in_minutes` int DEFAULT NULL COMMENT '持续时间（分钟）',
  `distance` int DEFAULT NULL COMMENT '距离',
  `distance_unit` varchar(2) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '距离单位',
  `from_place` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '起始地点',
  `to_place` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '目的地',
  `place` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '地点',
  `importance_level` int NOT NULL COMMENT '重要性等级 1-5',
  `evidence` text COLLATE utf8mb4_unicode_ci COMMENT '事件证据',
  `end_date` date DEFAULT NULL COMMENT '结束日期',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `timeline_event_id` (`timeline_event_id`),
  KEY `life_event_type_id` (`life_event_type_id`),
  KEY `emotion_id` (`emotion_id`),
  KEY `paid_by_poet_id` (`paid_by_poet_id`),
  CONSTRAINT `life_events_ibfk_1` FOREIGN KEY (`timeline_event_id`) REFERENCES `timeline_events` (`id`),
  CONSTRAINT `life_events_ibfk_2` FOREIGN KEY (`life_event_type_id`) REFERENCES `life_event_types` (`id`),
  CONSTRAINT `life_events_ibfk_3` FOREIGN KEY (`emotion_id`) REFERENCES `emotions` (`id`),
  CONSTRAINT `life_events_ibfk_4` FOREIGN KEY (`paid_by_poet_id`) REFERENCES `poets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `life_events`
--

LOCK TABLES `life_events` WRITE;
/*!40000 ALTER TABLE `life_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `life_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notes`
--

DROP TABLE IF EXISTS `notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notes` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '笔记ID',
  `poet_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '诗人ID',
  `vault_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '保险库ID',
  `author_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '作者ID',
  `emotion_id` int DEFAULT NULL COMMENT '情感ID',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '笔记标题',
  `body` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '笔记内容',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `poet_id` (`poet_id`),
  CONSTRAINT `notes_ibfk_1` FOREIGN KEY (`poet_id`) REFERENCES `poets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notes`
--

LOCK TABLES `notes` WRITE;
/*!40000 ALTER TABLE `notes` DISABLE KEYS */;
/*!40000 ALTER TABLE `notes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `poet_tag`
--

DROP TABLE IF EXISTS `poet_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `poet_tag` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '诗人标签关联ID',
  `poet_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '诗人ID',
  `tag_id` bigint NOT NULL COMMENT '标签ID',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `poet_id` (`poet_id`),
  KEY `tag_id` (`tag_id`),
  CONSTRAINT `poet_tag_ibfk_1` FOREIGN KEY (`poet_id`) REFERENCES `poets` (`id`),
  CONSTRAINT `poet_tag_ibfk_2` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `poet_tag`
--

LOCK TABLES `poet_tag` WRITE;
/*!40000 ALTER TABLE `poet_tag` DISABLE KEYS */;
/*!40000 ALTER TABLE `poet_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `poets`
--

DROP TABLE IF EXISTS `poets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `poets` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '诗人唯一标识',
  `vault_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '所属保险库ID',
  `first_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名',
  `middle_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '中间名',
  `last_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '姓',
  `nickname` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '昵称',
  `maiden_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '婚前姓',
  `suffix` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '后缀',
  `prefix` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '前缀',
  `alias` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '字号、别号',
  `birth_year` int DEFAULT NULL COMMENT '出生年份',
  `death_year` int DEFAULT NULL COMMENT '逝世年份',
  `birth_place` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '出生地',
  `death_place` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '逝世地',
  `occupation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '职业/官职',
  `social_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '社会地位',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '人物描述',
  `avatar` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '头像',
  `can_be_deleted` tinyint(1) NOT NULL COMMENT '是否可删除',
  `show_quick_facts` tinyint(1) NOT NULL COMMENT '是否显示快速事实',
  `listed` tinyint(1) NOT NULL COMMENT '是否在列表中显示',
  `vcard` mediumtext COLLATE utf8mb4_unicode_ci COMMENT 'vCard数据',
  `gender_id` int DEFAULT NULL COMMENT '性别ID',
  `pronoun_id` int DEFAULT NULL COMMENT '代词ID',
  `religion_id` int DEFAULT NULL COMMENT '宗教ID',
  `file_id` int DEFAULT NULL COMMENT '文件ID',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `gender_id` (`gender_id`),
  KEY `pronoun_id` (`pronoun_id`),
  KEY `religion_id` (`religion_id`),
  KEY `file_id` (`file_id`),
  CONSTRAINT `poets_ibfk_1` FOREIGN KEY (`gender_id`) REFERENCES `genders` (`id`),
  CONSTRAINT `poets_ibfk_2` FOREIGN KEY (`pronoun_id`) REFERENCES `pronouns` (`id`),
  CONSTRAINT `poets_ibfk_3` FOREIGN KEY (`religion_id`) REFERENCES `religions` (`id`),
  CONSTRAINT `poets_ibfk_4` FOREIGN KEY (`file_id`) REFERENCES `files` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `poets`
--

LOCK TABLES `poets` WRITE;
/*!40000 ALTER TABLE `poets` DISABLE KEYS */;
/*!40000 ALTER TABLE `poets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `positions`
--

DROP TABLE IF EXISTS `positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `positions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '职位名称',
  `level` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '职位级别: junior, mid, senior, lead, manager, director, c-level',
  `department` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '职位描述',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `positions`
--

LOCK TABLES `positions` WRITE;
/*!40000 ALTER TABLE `positions` DISABLE KEYS */;
/*!40000 ALTER TABLE `positions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '项目名称',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '项目描述',
  `start_date` datetime DEFAULT NULL COMMENT '开始时间',
  `end_date` datetime DEFAULT NULL COMMENT '结束时间',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '项目状态: planning, active, completed, cancelled',
  `technology_stack` text COLLATE utf8mb4_unicode_ci COMMENT '技术栈',
  `project_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '项目链接',
  `company_id` int DEFAULT NULL COMMENT '所属公司',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `company_id` (`company_id`),
  CONSTRAINT `projects_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects`
--

LOCK TABLES `projects` WRITE;
/*!40000 ALTER TABLE `projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pronouns`
--

DROP TABLE IF EXISTS `pronouns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pronouns` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '代词ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '代词名称',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pronouns`
--

LOCK TABLES `pronouns` WRITE;
/*!40000 ALTER TABLE `pronouns` DISABLE KEYS */;
/*!40000 ALTER TABLE `pronouns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `relationship_group_types`
--

DROP TABLE IF EXISTS `relationship_group_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `relationship_group_types` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '关系组类型ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '关系组类型名称',
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关系组类型',
  `can_be_deleted` int NOT NULL COMMENT '是否可删除',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `relationship_group_types`
--

LOCK TABLES `relationship_group_types` WRITE;
/*!40000 ALTER TABLE `relationship_group_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `relationship_group_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `relationship_types`
--

DROP TABLE IF EXISTS `relationship_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `relationship_types` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '关系类型ID',
  `relationship_group_type_id` bigint NOT NULL COMMENT '关系组类型ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关系类型名称',
  `name_translation_key` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '翻译键',
  `name_reverse_relationship` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '反向关系名称',
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关系类型',
  `can_be_deleted` int NOT NULL COMMENT '是否可删除',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `relationship_group_type_id` (`relationship_group_type_id`),
  CONSTRAINT `relationship_types_ibfk_1` FOREIGN KEY (`relationship_group_type_id`) REFERENCES `relationship_group_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `relationship_types`
--

LOCK TABLES `relationship_types` WRITE;
/*!40000 ALTER TABLE `relationship_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `relationship_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `relationships`
--

DROP TABLE IF EXISTS `relationships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `relationships` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '关系ID',
  `relationship_type_id` bigint NOT NULL COMMENT '关系类型ID',
  `poet_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '诗人ID',
  `related_poet_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '相关诗人ID',
  `start_year` int DEFAULT NULL COMMENT '关系开始年份',
  `end_year` int DEFAULT NULL COMMENT '关系结束年份',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '关系描述',
  `evidence` text COLLATE utf8mb4_unicode_ci COMMENT '关系证据（文献记载）',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `relationship_type_id` (`relationship_type_id`),
  KEY `poet_id` (`poet_id`),
  KEY `related_poet_id` (`related_poet_id`),
  CONSTRAINT `relationships_ibfk_1` FOREIGN KEY (`relationship_type_id`) REFERENCES `relationship_types` (`id`),
  CONSTRAINT `relationships_ibfk_2` FOREIGN KEY (`poet_id`) REFERENCES `poets` (`id`),
  CONSTRAINT `relationships_ibfk_3` FOREIGN KEY (`related_poet_id`) REFERENCES `poets` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `relationships`
--

LOCK TABLES `relationships` WRITE;
/*!40000 ALTER TABLE `relationships` DISABLE KEYS */;
/*!40000 ALTER TABLE `relationships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `religions`
--

DROP TABLE IF EXISTS `religions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `religions` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '宗教ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '宗教名称',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `religions`
--

LOCK TABLES `religions` WRITE;
/*!40000 ALTER TABLE `religions` DISABLE KEYS */;
/*!40000 ALTER TABLE `religions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `skills`
--

DROP TABLE IF EXISTS `skills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `skills` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '技能名称',
  `category` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '技能类别: technical, soft, language, tool',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '技能描述',
  `icon` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '技能图标',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `skills`
--

LOCK TABLES `skills` WRITE;
/*!40000 ALTER TABLE `skills` DISABLE KEYS */;
/*!40000 ALTER TABLE `skills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tags` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '标签ID',
  `vault_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '保险库ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签名称',
  `name_translation_key` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签名称翻译键',
  `slug` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签别名',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '标签描述',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tags`
--

LOCK TABLES `tags` WRITE;
/*!40000 ALTER TABLE `tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `talent_certifications`
--

DROP TABLE IF EXISTS `talent_certifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `talent_certifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `talent_id` int NOT NULL,
  `certification_id` int NOT NULL,
  `issue_date` datetime DEFAULT NULL COMMENT '获得日期',
  `expiry_date` datetime DEFAULT NULL COMMENT '过期日期',
  `certificate_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '证书文件URL',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `talent_id` (`talent_id`),
  KEY `certification_id` (`certification_id`),
  CONSTRAINT `talent_certifications_ibfk_1` FOREIGN KEY (`talent_id`) REFERENCES `talents` (`id`),
  CONSTRAINT `talent_certifications_ibfk_2` FOREIGN KEY (`certification_id`) REFERENCES `certifications` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `talent_certifications`
--

LOCK TABLES `talent_certifications` WRITE;
/*!40000 ALTER TABLE `talent_certifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `talent_certifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `talent_project_association`
--

DROP TABLE IF EXISTS `talent_project_association`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `talent_project_association` (
  `talent_id` int NOT NULL,
  `project_id` int NOT NULL,
  `role` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `contribution` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`talent_id`,`project_id`),
  KEY `project_id` (`project_id`),
  CONSTRAINT `talent_project_association_ibfk_1` FOREIGN KEY (`talent_id`) REFERENCES `talents` (`id`),
  CONSTRAINT `talent_project_association_ibfk_2` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `talent_project_association`
--

LOCK TABLES `talent_project_association` WRITE;
/*!40000 ALTER TABLE `talent_project_association` DISABLE KEYS */;
/*!40000 ALTER TABLE `talent_project_association` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `talent_relationships`
--

DROP TABLE IF EXISTS `talent_relationships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `talent_relationships` (
  `id` int NOT NULL AUTO_INCREMENT,
  `talent_id` int NOT NULL,
  `related_talent_id` int NOT NULL,
  `relationship_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '关系类型: colleague, mentor, mentee, friend, classmate, family',
  `strength` int DEFAULT NULL COMMENT '关系强度: 1-5',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '关系描述',
  `start_date` datetime DEFAULT NULL COMMENT '关系开始时间',
  `end_date` datetime DEFAULT NULL COMMENT '关系结束时间',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `talent_id` (`talent_id`),
  KEY `related_talent_id` (`related_talent_id`),
  CONSTRAINT `talent_relationships_ibfk_1` FOREIGN KEY (`talent_id`) REFERENCES `talents` (`id`),
  CONSTRAINT `talent_relationships_ibfk_2` FOREIGN KEY (`related_talent_id`) REFERENCES `talents` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `talent_relationships`
--

LOCK TABLES `talent_relationships` WRITE;
/*!40000 ALTER TABLE `talent_relationships` DISABLE KEYS */;
/*!40000 ALTER TABLE `talent_relationships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `talent_skill_association`
--

DROP TABLE IF EXISTS `talent_skill_association`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `talent_skill_association` (
  `talent_id` int NOT NULL,
  `skill_id` int NOT NULL,
  `proficiency_level` int DEFAULT NULL,
  `years_of_experience` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`talent_id`,`skill_id`),
  KEY `skill_id` (`skill_id`),
  CONSTRAINT `talent_skill_association_ibfk_1` FOREIGN KEY (`talent_id`) REFERENCES `talents` (`id`),
  CONSTRAINT `talent_skill_association_ibfk_2` FOREIGN KEY (`skill_id`) REFERENCES `skills` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `talent_skill_association`
--

LOCK TABLES `talent_skill_association` WRITE;
/*!40000 ALTER TABLE `talent_skill_association` DISABLE KEYS */;
/*!40000 ALTER TABLE `talent_skill_association` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `talent_tags`
--

DROP TABLE IF EXISTS `talent_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `talent_tags` (
  `id` int NOT NULL AUTO_INCREMENT,
  `talent_id` int NOT NULL,
  `tag_id` bigint NOT NULL,
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `talent_id` (`talent_id`),
  KEY `tag_id` (`tag_id`),
  CONSTRAINT `talent_tags_ibfk_1` FOREIGN KEY (`talent_id`) REFERENCES `talents` (`id`),
  CONSTRAINT `talent_tags_ibfk_2` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `talent_tags`
--

LOCK TABLES `talent_tags` WRITE;
/*!40000 ALTER TABLE `talent_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `talent_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `talents`
--

DROP TABLE IF EXISTS `talents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `talents` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '姓名',
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '电话',
  `avatar` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '头像URL',
  `gender` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '性别',
  `birth_date` datetime DEFAULT NULL COMMENT '出生日期',
  `location` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所在地',
  `nationality` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '国籍',
  `current_position` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '当前职位',
  `current_company` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '当前公司',
  `industry` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属行业',
  `years_of_experience` int DEFAULT NULL COMMENT '工作年限',
  `education_level` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '最高学历',
  `major` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '专业',
  `university` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '毕业院校',
  `graduation_year` int DEFAULT NULL COMMENT '毕业年份',
  `resume_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '简历文件URL',
  `linkedin_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'LinkedIn链接',
  `github_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'GitHub链接',
  `portfolio_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '作品集链接',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态: active, inactive, archived',
  `is_deleted` tinyint(1) DEFAULT NULL COMMENT '软删除标记',
  `created_at` datetime DEFAULT NULL COMMENT '创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `talents`
--

LOCK TABLES `talents` WRITE;
/*!40000 ALTER TABLE `talents` DISABLE KEYS */;
/*!40000 ALTER TABLE `talents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timeline_events`
--

DROP TABLE IF EXISTS `timeline_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timeline_events` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '时间线事件ID',
  `vault_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '所属保险库ID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '事件名称',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '事件描述',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timeline_events`
--

LOCK TABLES `timeline_events` WRITE;
/*!40000 ALTER TABLE `timeline_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `timeline_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_experiences`
--

DROP TABLE IF EXISTS `work_experiences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_experiences` (
  `id` int NOT NULL AUTO_INCREMENT,
  `talent_id` int NOT NULL,
  `company_id` int NOT NULL,
  `position_id` int NOT NULL,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '职位名称',
  `start_date` datetime NOT NULL COMMENT '开始时间',
  `end_date` datetime DEFAULT NULL COMMENT '结束时间',
  `is_current` tinyint(1) DEFAULT NULL COMMENT '是否当前工作',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '工作描述',
  `achievements` text COLLATE utf8mb4_unicode_ci COMMENT '主要成就',
  `is_deleted` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `talent_id` (`talent_id`),
  KEY `company_id` (`company_id`),
  KEY `position_id` (`position_id`),
  CONSTRAINT `work_experiences_ibfk_1` FOREIGN KEY (`talent_id`) REFERENCES `talents` (`id`),
  CONSTRAINT `work_experiences_ibfk_2` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`),
  CONSTRAINT `work_experiences_ibfk_3` FOREIGN KEY (`position_id`) REFERENCES `positions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_experiences`
--

LOCK TABLES `work_experiences` WRITE;
/*!40000 ALTER TABLE `work_experiences` DISABLE KEYS */;
/*!40000 ALTER TABLE `work_experiences` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_relations`
--

DROP TABLE IF EXISTS `work_relations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_relations` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '作品关联ID',
  `work_id` bigint NOT NULL COMMENT '作品ID',
  `related_work_id` bigint NOT NULL COMMENT '关联作品ID',
  `relation_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '关联类型：引用、续写、和诗等',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '关联描述',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `work_id` (`work_id`),
  KEY `related_work_id` (`related_work_id`),
  CONSTRAINT `work_relations_ibfk_1` FOREIGN KEY (`work_id`) REFERENCES `works` (`id`),
  CONSTRAINT `work_relations_ibfk_2` FOREIGN KEY (`related_work_id`) REFERENCES `works` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_relations`
--

LOCK TABLES `work_relations` WRITE;
/*!40000 ALTER TABLE `work_relations` DISABLE KEYS */;
/*!40000 ALTER TABLE `work_relations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_tag`
--

DROP TABLE IF EXISTS `work_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_tag` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '作品标签关联ID',
  `work_id` bigint NOT NULL COMMENT '作品ID',
  `tag_id` bigint NOT NULL COMMENT '标签ID',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `work_id` (`work_id`),
  KEY `tag_id` (`tag_id`),
  CONSTRAINT `work_tag_ibfk_1` FOREIGN KEY (`work_id`) REFERENCES `works` (`id`),
  CONSTRAINT `work_tag_ibfk_2` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_tag`
--

LOCK TABLES `work_tag` WRITE;
/*!40000 ALTER TABLE `work_tag` DISABLE KEYS */;
/*!40000 ALTER TABLE `work_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_types`
--

DROP TABLE IF EXISTS `work_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_types` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '作品类型ID',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '作品类型名称',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '作品类型描述',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_types`
--

LOCK TABLES `work_types` WRITE;
/*!40000 ALTER TABLE `work_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `work_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `works`
--

DROP TABLE IF EXISTS `works`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `works` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '作品ID',
  `poet_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '诗人ID',
  `vault_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '所属保险库ID',
  `work_type_id` bigint NOT NULL COMMENT '作品类型ID',
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '作品标题',
  `content` text COLLATE utf8mb4_unicode_ci COMMENT '作品内容',
  `creation_year` int DEFAULT NULL COMMENT '创作年份',
  `creation_location` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创作地点',
  `background` text COLLATE utf8mb4_unicode_ci COMMENT '创作背景',
  `theme` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '主题',
  `style` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '风格',
  `file_id` bigint DEFAULT NULL COMMENT '相关文件',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `poet_id` (`poet_id`),
  KEY `work_type_id` (`work_type_id`),
  CONSTRAINT `works_ibfk_1` FOREIGN KEY (`poet_id`) REFERENCES `poets` (`id`),
  CONSTRAINT `works_ibfk_2` FOREIGN KEY (`work_type_id`) REFERENCES `work_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `works`
--

LOCK TABLES `works` WRITE;
/*!40000 ALTER TABLE `works` DISABLE KEYS */;
/*!40000 ALTER TABLE `works` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-08-29 20:50:41
