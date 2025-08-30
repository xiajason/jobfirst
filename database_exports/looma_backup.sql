-- MySQL dump 10.13  Distrib 9.4.0, for macos15.4 (arm64)
--
-- Host: localhost    Database: looma
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
-- Table structure for table `app_config`
--

DROP TABLE IF EXISTS `app_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_config` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名称',
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用代码',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '应用描述',
  `type` bigint NOT NULL DEFAULT '20' COMMENT '应用类型(10=内置应用,20=扩展应用)',
  `login_enable` bigint NOT NULL DEFAULT '10' COMMENT '登录验证开关(10=开启,20=关闭)',
  `auth_enable` bigint NOT NULL DEFAULT '10' COMMENT '权限验证开关(10=开启,20=关闭)',
  `exclusion_urls` text COLLATE utf8mb4_unicode_ci COMMENT '排除验证的URL列表(JSON格式)',
  `config_data` text COLLATE utf8mb4_unicode_ci COMMENT '应用配置数据(JSON格式)',
  `status` bigint NOT NULL DEFAULT '10' COMMENT '状态(10=启用,20=禁用)',
  `sort_order` bigint NOT NULL DEFAULT '0' COMMENT '排序',
  `version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '版本号',
  `author` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '作者',
  `homepage` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '主页',
  `icon` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '图标',
  `color` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '主题色',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_app_config_code` (`code`),
  KEY `idx_app_config_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_config`
--

LOCK TABLES `app_config` WRITE;
/*!40000 ALTER TABLE `app_config` DISABLE KEYS */;
INSERT INTO `app_config` VALUES (1,'2025-08-24 08:24:00.744','2025-08-24 08:24:00.744',NULL,'系统管理','admin','系统管理后台，包含用户、角色、权限管理等功能',10,10,10,'','',10,1,'1.0.0','Looma Team','','admin','#409EFF'),(2,'2025-08-24 08:24:00.745','2025-08-24 08:24:00.745',NULL,'用户中心','user','用户中心，包含用户注册、登录、个人信息管理等功能',10,10,10,'','',10,2,'1.0.0','Looma Team','','user','#67C23A'),(3,'2025-08-24 08:24:00.747','2025-08-24 08:24:00.747',NULL,'博客系统','blog','博客系统，包含文章发布、评论管理等功能',10,10,10,'','',10,3,'1.0.0','Looma Team','','blog','#E6A23C');
/*!40000 ALTER TABLE `app_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `apps`
--

DROP TABLE IF EXISTS `apps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名称',
  `code` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用代码',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用描述',
  `version` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '版本号',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_apps_code` (`code`),
  KEY `idx_apps_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `apps`
--

LOCK TABLES `apps` WRITE;
/*!40000 ALTER TABLE `apps` DISABLE KEYS */;
INSERT INTO `apps` VALUES (1,NULL,NULL,NULL,'系统管理','system','系统管理应用','1.0.0',1),(2,NULL,NULL,NULL,'内容管理','content','内容管理应用','1.0.0',1),(3,NULL,NULL,NULL,'用户管理','user','用户管理应用','1.0.0',1);
/*!40000 ALTER TABLE `apps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `casbin_rule`
--

DROP TABLE IF EXISTS `casbin_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `casbin_rule` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ptype` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `v0` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `v1` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `v2` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `v3` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `v4` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `v5` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_casbin_rule` (`ptype`,`v0`,`v1`,`v2`,`v3`,`v4`,`v5`)
) ENGINE=InnoDB AUTO_INCREMENT=172 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `casbin_rule`
--

LOCK TABLES `casbin_rule` WRITE;
/*!40000 ALTER TABLE `casbin_rule` DISABLE KEYS */;
INSERT INTO `casbin_rule` VALUES (171,'g','user_1','super_admin','','','',''),(158,'p','content_editor','comment','create','','',''),(157,'p','content_editor','comment','read','','',''),(159,'p','content_editor','comment','update','','',''),(155,'p','content_editor','post','create','','',''),(154,'p','content_editor','post','read','','',''),(156,'p','content_editor','post','update','','',''),(161,'p','content_editor','tag','create','','',''),(160,'p','content_editor','tag','read','','',''),(162,'p','content_editor','tag','update','','',''),(166,'p','content_reviewer','comment','moderate','','',''),(165,'p','content_reviewer','comment','read','','',''),(164,'p','content_reviewer','post','approve','','',''),(163,'p','content_reviewer','post','read','','',''),(167,'p','content_reviewer','tag','read','','',''),(129,'p','dept_manager','comment','create','','',''),(131,'p','dept_manager','comment','delete','','',''),(132,'p','dept_manager','comment','moderate','','',''),(128,'p','dept_manager','comment','read','','',''),(130,'p','dept_manager','comment','update','','',''),(123,'p','dept_manager','department','config','','',''),(122,'p','dept_manager','department','manage','','',''),(127,'p','dept_manager','post','approve','','',''),(120,'p','dept_manager','post','create','','',''),(126,'p','dept_manager','post','publish','','',''),(119,'p','dept_manager','post','read','','',''),(121,'p','dept_manager','post','update','','',''),(125,'p','dept_manager','project','config','','',''),(124,'p','dept_manager','project','manage','','',''),(136,'p','dept_manager','route','read','','',''),(134,'p','dept_manager','tag','create','','',''),(133,'p','dept_manager','tag','read','','',''),(135,'p','dept_manager','tag','update','','',''),(117,'p','dept_manager','user','read','','',''),(118,'p','dept_manager','user','update','','',''),(169,'p','guest','comment','read','','',''),(168,'p','guest','post','read','','',''),(170,'p','guest','tag','read','','',''),(108,'p','org_admin','comment','create','','',''),(110,'p','org_admin','comment','delete','','',''),(111,'p','org_admin','comment','moderate','','',''),(107,'p','org_admin','comment','read','','',''),(109,'p','org_admin','comment','update','','',''),(102,'p','org_admin','department','config','','',''),(101,'p','org_admin','department','manage','','',''),(100,'p','org_admin','organization','config','','',''),(99,'p','org_admin','organization','manage','','',''),(106,'p','org_admin','post','approve','','',''),(97,'p','org_admin','post','create','','',''),(105,'p','org_admin','post','publish','','',''),(96,'p','org_admin','post','read','','',''),(98,'p','org_admin','post','update','','',''),(104,'p','org_admin','project','config','','',''),(103,'p','org_admin','project','manage','','',''),(116,'p','org_admin','route','read','','',''),(113,'p','org_admin','tag','create','','',''),(115,'p','org_admin','tag','delete','','',''),(112,'p','org_admin','tag','read','','',''),(114,'p','org_admin','tag','update','','',''),(94,'p','org_admin','user','create','','',''),(93,'p','org_admin','user','read','','',''),(95,'p','org_admin','user','update','','',''),(146,'p','project_lead','comment','create','','',''),(148,'p','project_lead','comment','delete','','',''),(149,'p','project_lead','comment','moderate','','',''),(145,'p','project_lead','comment','read','','',''),(147,'p','project_lead','comment','update','','',''),(144,'p','project_lead','post','approve','','',''),(139,'p','project_lead','post','create','','',''),(143,'p','project_lead','post','publish','','',''),(138,'p','project_lead','post','read','','',''),(140,'p','project_lead','post','update','','',''),(142,'p','project_lead','project','config','','',''),(141,'p','project_lead','project','manage','','',''),(153,'p','project_lead','route','read','','',''),(151,'p','project_lead','tag','create','','',''),(150,'p','project_lead','tag','read','','',''),(152,'p','project_lead','tag','update','','',''),(137,'p','project_lead','user','read','','',''),(46,'p','super_admin','app_config','create','','',''),(48,'p','super_admin','app_config','delete','','',''),(45,'p','super_admin','app_config','read','','',''),(47,'p','super_admin','app_config','update','','',''),(23,'p','super_admin','comment','create','','',''),(25,'p','super_admin','comment','delete','','',''),(26,'p','super_admin','comment','moderate','','',''),(22,'p','super_admin','comment','read','','',''),(24,'p','super_admin','comment','update','','',''),(43,'p','super_admin','dashboard','read','','',''),(44,'p','super_admin','dashboard','write','','',''),(17,'p','super_admin','department','config','','',''),(16,'p','super_admin','department','manage','','',''),(15,'p','super_admin','organization','config','','',''),(14,'p','super_admin','organization','manage','','',''),(36,'p','super_admin','permission','create','','',''),(38,'p','super_admin','permission','delete','','',''),(35,'p','super_admin','permission','read','','',''),(37,'p','super_admin','permission','update','','',''),(21,'p','super_admin','post','approve','','',''),(6,'p','super_admin','post','create','','',''),(8,'p','super_admin','post','delete','','',''),(20,'p','super_admin','post','publish','','',''),(5,'p','super_admin','post','read','','',''),(7,'p','super_admin','post','update','','',''),(19,'p','super_admin','project','config','','',''),(18,'p','super_admin','project','manage','','',''),(32,'p','super_admin','role','create','','',''),(34,'p','super_admin','role','delete','','',''),(31,'p','super_admin','role','read','','',''),(33,'p','super_admin','role','update','','',''),(40,'p','super_admin','route','create','','',''),(42,'p','super_admin','route','delete','','',''),(39,'p','super_admin','route','read','','',''),(41,'p','super_admin','route','update','','',''),(10,'p','super_admin','system','backup','','',''),(9,'p','super_admin','system','config','','',''),(11,'p','super_admin','system','restore','','',''),(28,'p','super_admin','tag','create','','',''),(30,'p','super_admin','tag','delete','','',''),(27,'p','super_admin','tag','read','','',''),(29,'p','super_admin','tag','update','','',''),(13,'p','super_admin','tenant','config','','',''),(12,'p','super_admin','tenant','manage','','',''),(2,'p','super_admin','user','create','','',''),(4,'p','super_admin','user','delete','','',''),(1,'p','super_admin','user','read','','',''),(3,'p','super_admin','user','update','','',''),(76,'p','tenant_admin','comment','create','','',''),(78,'p','tenant_admin','comment','delete','','',''),(79,'p','tenant_admin','comment','moderate','','',''),(75,'p','tenant_admin','comment','read','','',''),(77,'p','tenant_admin','comment','update','','',''),(70,'p','tenant_admin','department','config','','',''),(69,'p','tenant_admin','department','manage','','',''),(68,'p','tenant_admin','organization','config','','',''),(67,'p','tenant_admin','organization','manage','','',''),(88,'p','tenant_admin','permission','create','','',''),(87,'p','tenant_admin','permission','read','','',''),(89,'p','tenant_admin','permission','update','','',''),(74,'p','tenant_admin','post','approve','','',''),(62,'p','tenant_admin','post','create','','',''),(64,'p','tenant_admin','post','delete','','',''),(73,'p','tenant_admin','post','publish','','',''),(61,'p','tenant_admin','post','read','','',''),(63,'p','tenant_admin','post','update','','',''),(72,'p','tenant_admin','project','config','','',''),(71,'p','tenant_admin','project','manage','','',''),(85,'p','tenant_admin','role','create','','',''),(84,'p','tenant_admin','role','read','','',''),(86,'p','tenant_admin','role','update','','',''),(91,'p','tenant_admin','route','create','','',''),(90,'p','tenant_admin','route','read','','',''),(92,'p','tenant_admin','route','update','','',''),(81,'p','tenant_admin','tag','create','','',''),(83,'p','tenant_admin','tag','delete','','',''),(80,'p','tenant_admin','tag','read','','',''),(82,'p','tenant_admin','tag','update','','',''),(66,'p','tenant_admin','tenant','config','','',''),(65,'p','tenant_admin','tenant','manage','','',''),(59,'p','tenant_admin','user','create','','',''),(58,'p','tenant_admin','user','read','','',''),(60,'p','tenant_admin','user','update','','',''),(55,'p','user','comment','create','','',''),(54,'p','user','comment','read','','',''),(56,'p','user','comment','update','','',''),(52,'p','user','post','create','','',''),(51,'p','user','post','read','','',''),(53,'p','user','post','update','','',''),(57,'p','user','tag','read','','',''),(49,'p','user','user','read','','',''),(50,'p','user','user','update','','','');
/*!40000 ALTER TABLE `casbin_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `post_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `parent_id` bigint unsigned DEFAULT NULL,
  `is_approved` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_comments_deleted_at` (`deleted_at`),
  KEY `fk_comments_children` (`parent_id`),
  KEY `fk_posts_comments` (`post_id`),
  KEY `fk_users_comments` (`user_id`),
  CONSTRAINT `fk_comments_children` FOREIGN KEY (`parent_id`) REFERENCES `comments` (`id`),
  CONSTRAINT `fk_posts_comments` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`),
  CONSTRAINT `fk_users_comments` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comments`
--

LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group_roles`
--

DROP TABLE IF EXISTS `group_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `group_roles` (
  `user_group_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  `assigned_at` datetime(3) DEFAULT NULL,
  `expires_at` datetime(3) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`user_group_id`,`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_roles`
--

LOCK TABLES `group_roles` WRITE;
/*!40000 ALTER TABLE `group_roles` DISABLE KEYS */;
INSERT INTO `group_roles` VALUES (1,1,NULL,NULL,1),(2,4,NULL,NULL,1),(3,8,NULL,NULL,1),(3,9,NULL,NULL,1),(4,7,NULL,NULL,1),(4,8,NULL,NULL,1),(5,9,NULL,NULL,1),(6,3,NULL,NULL,1);
/*!40000 ALTER TABLE `group_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menus`
--

DROP TABLE IF EXISTS `menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menus` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `pid` bigint unsigned DEFAULT '0' COMMENT '父级ID',
  `id_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ID路径(逗号分隔)',
  `path_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '菜单路径名称',
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '菜单名称',
  `title` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '菜单标题',
  `icon` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '菜单图标',
  `path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '菜单路径',
  `component` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '组件路径',
  `component_tpl` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '组件模板',
  `model_id` bigint unsigned DEFAULT '0' COMMENT '关联模型ID',
  `app_id` bigint unsigned DEFAULT '0' COMMENT '关联应用ID',
  `sort_num` bigint DEFAULT '0' COMMENT '排序序号',
  `is_show` tinyint(1) DEFAULT '1' COMMENT '是否显示',
  `is_cache` tinyint(1) DEFAULT '0' COMMENT '是否缓存',
  `is_frame` tinyint(1) DEFAULT '0' COMMENT '是否外链',
  `is_link` tinyint(1) DEFAULT '0' COMMENT '是否链接',
  `link_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '链接地址',
  `permission` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '权限标识',
  `status` bigint DEFAULT '1' COMMENT '状态(0:禁用,1:启用)',
  `remark` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注',
  `meta` json DEFAULT NULL COMMENT '元数据',
  PRIMARY KEY (`id`),
  KEY `idx_menus_deleted_at` (`deleted_at`),
  KEY `fk_menus_model` (`model_id`),
  KEY `fk_menus_app` (`app_id`),
  KEY `fk_menus_children` (`pid`),
  CONSTRAINT `fk_menus_app` FOREIGN KEY (`app_id`) REFERENCES `apps` (`id`),
  CONSTRAINT `fk_menus_children` FOREIGN KEY (`pid`) REFERENCES `menus` (`id`),
  CONSTRAINT `fk_menus_model` FOREIGN KEY (`model_id`) REFERENCES `models` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menus`
--

LOCK TABLES `menus` WRITE;
/*!40000 ALTER TABLE `menus` DISABLE KEYS */;
INSERT INTO `menus` VALUES (1,NULL,NULL,NULL,NULL,NULL,NULL,'system','系统管理','setting','/admin/system','Layout',NULL,NULL,1,1,1,0,0,0,NULL,'system:view',1,NULL,NULL),(2,NULL,NULL,NULL,NULL,NULL,NULL,'user','用户管理','user','/admin/users','Layout',NULL,NULL,3,2,1,0,0,0,NULL,'user:view',1,NULL,NULL),(3,NULL,NULL,NULL,NULL,NULL,NULL,'content','内容管理','content','/admin/posts','Layout',NULL,NULL,2,3,1,0,0,0,NULL,'content:view',1,NULL,NULL),(4,NULL,NULL,NULL,1,NULL,NULL,'dashboard','仪表盘','dashboard','/admin','system/dashboard/index',NULL,NULL,1,1,1,0,0,0,NULL,'system:dashboard:view',1,NULL,NULL),(5,NULL,NULL,NULL,1,NULL,NULL,'menu','菜单管理','menu','/admin/menus','system/menu/index',NULL,NULL,1,2,1,0,0,0,NULL,'system:menu:view',1,NULL,NULL),(6,NULL,NULL,NULL,1,NULL,NULL,'route','路由管理','route','/system/route','system/route/index',NULL,NULL,1,3,1,0,0,0,NULL,'system:route:view',1,NULL,NULL),(7,NULL,NULL,NULL,1,NULL,NULL,'app','应用管理','app','/system/app','system/app/index',NULL,NULL,1,4,1,0,0,0,NULL,'system:app:view',1,NULL,NULL),(8,NULL,NULL,NULL,1,NULL,NULL,'model','模型管理','model','/system/model','system/model/index',NULL,NULL,1,5,1,0,0,0,NULL,'system:model:view',1,NULL,NULL),(9,NULL,NULL,NULL,2,NULL,NULL,'user-list','用户列表','user-list','/admin/users','user/list/index',NULL,NULL,3,1,1,0,0,0,NULL,'user:list:view',1,NULL,NULL),(10,NULL,NULL,NULL,2,NULL,NULL,'role','角色管理','role','/admin/roles','user/role/index',NULL,NULL,3,2,1,0,0,0,NULL,'user:role:view',1,NULL,NULL),(11,NULL,NULL,NULL,2,NULL,NULL,'permission','权限管理','permission','/user/permission','user/permission/index',NULL,NULL,3,3,1,0,0,0,NULL,'user:permission:view',1,NULL,NULL),(12,NULL,NULL,NULL,2,NULL,NULL,'user-group','用户组','user-group','/user/group','user/group/index',NULL,NULL,3,4,1,0,0,0,NULL,'user:group:view',1,NULL,NULL),(13,NULL,NULL,NULL,3,NULL,NULL,'post','文章管理','post','/admin/posts','content/post/index',NULL,NULL,2,1,1,0,0,0,NULL,'content:post:view',1,NULL,NULL),(14,NULL,NULL,NULL,3,NULL,NULL,'tag','标签管理','tag','/admin/tags','content/tag/index',NULL,NULL,2,2,1,0,0,0,NULL,'content:tag:view',1,NULL,NULL),(15,NULL,NULL,NULL,3,NULL,NULL,'comment','评论管理','comment','/admin/comments','content/comment/index',NULL,NULL,2,3,1,0,0,0,NULL,'content:comment:view',1,NULL,NULL);
/*!40000 ALTER TABLE `menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `models`
--

DROP TABLE IF EXISTS `models`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `models` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模型名称',
  `model_table` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '表名',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型描述',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  KEY `idx_models_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `models`
--

LOCK TABLES `models` WRITE;
/*!40000 ALTER TABLE `models` DISABLE KEYS */;
/*!40000 ALTER TABLE `models` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `permission_audit_logs`
--

DROP TABLE IF EXISTS `permission_audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permission_audit_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `action` longtext COLLATE utf8mb4_unicode_ci,
  `resource` longtext COLLATE utf8mb4_unicode_ci,
  `permission` longtext COLLATE utf8mb4_unicode_ci,
  `result` tinyint(1) DEFAULT NULL,
  `ip_address` longtext COLLATE utf8mb4_unicode_ci,
  `user_agent` longtext COLLATE utf8mb4_unicode_ci,
  `request_id` longtext COLLATE utf8mb4_unicode_ci,
  `session_id` longtext COLLATE utf8mb4_unicode_ci,
  `timestamp` datetime(3) DEFAULT NULL,
  `details` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `idx_permission_audit_logs_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permission_audit_logs`
--

LOCK TABLES `permission_audit_logs` WRITE;
/*!40000 ALTER TABLE `permission_audit_logs` DISABLE KEYS */;
INSERT INTO `permission_audit_logs` VALUES (1,'2025-08-24 07:03:29.332','2025-08-24 07:03:29.332',NULL,1,'check','system','system:config',1,'::1','curl/8.7.1','','','2025-08-24 07:03:29.332','');
/*!40000 ALTER TABLE `permission_audit_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `resource` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `action` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_permissions_name` (`name`),
  KEY `idx_permissions_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permissions`
--

LOCK TABLES `permissions` WRITE;
/*!40000 ALTER TABLE `permissions` DISABLE KEYS */;
INSERT INTO `permissions` VALUES (1,'2025-08-24 00:40:02.708','2025-08-24 00:40:02.708',NULL,'user_read','user','read','查看用户',1),(2,'2025-08-24 00:40:02.709','2025-08-24 00:40:02.709',NULL,'user_create','user','create','创建用户',1),(3,'2025-08-24 00:40:02.709','2025-08-24 00:40:02.709',NULL,'user_update','user','update','更新用户',1),(4,'2025-08-24 00:40:02.710','2025-08-24 00:40:02.710',NULL,'user_delete','user','delete','删除用户',1),(5,'2025-08-24 00:40:02.710','2025-08-24 00:40:02.710',NULL,'post_read','post','read','查看文章',1),(6,'2025-08-24 00:40:02.711','2025-08-24 00:40:02.711',NULL,'post_create','post','create','创建文章',1),(7,'2025-08-24 00:40:02.711','2025-08-24 00:40:02.711',NULL,'post_update','post','update','更新文章',1),(8,'2025-08-24 00:40:02.712','2025-08-24 00:40:02.712',NULL,'post_delete','post','delete','删除文章',1),(9,'2025-08-24 00:40:03.177','2025-08-24 00:40:03.177',NULL,'system_config','system','config','系统配置',1),(10,'2025-08-24 00:40:03.178','2025-08-24 00:40:03.178',NULL,'system_backup','system','backup','系统备份',1),(11,'2025-08-24 00:40:03.179','2025-08-24 00:40:03.179',NULL,'system_restore','system','restore','系统恢复',1),(12,'2025-08-24 00:40:03.179','2025-08-24 00:40:03.179',NULL,'tenant_manage','tenant','manage','租户管理',1),(13,'2025-08-24 00:40:03.180','2025-08-24 00:40:03.180',NULL,'tenant_config','tenant','config','租户配置',1),(14,'2025-08-24 00:40:03.180','2025-08-24 00:40:03.180',NULL,'org_manage','organization','manage','组织管理',1),(15,'2025-08-24 00:40:03.181','2025-08-24 00:40:03.181',NULL,'org_config','organization','config','组织配置',1),(16,'2025-08-24 00:40:03.182','2025-08-24 00:40:03.182',NULL,'dept_manage','department','manage','部门管理',1),(17,'2025-08-24 00:40:03.182','2025-08-24 00:40:03.182',NULL,'dept_config','department','config','部门配置',1),(18,'2025-08-24 00:40:03.183','2025-08-24 00:40:03.183',NULL,'project_manage','project','manage','项目管理',1),(19,'2025-08-24 00:40:03.183','2025-08-24 00:40:03.183',NULL,'project_config','project','config','项目配置',1),(20,'2025-08-24 00:40:03.186','2025-08-24 00:40:03.186',NULL,'post_publish','post','publish','发布文章',1),(21,'2025-08-24 00:40:03.186','2025-08-24 00:40:03.186',NULL,'post_approve','post','approve','审核文章',1),(22,'2025-08-24 00:40:03.187','2025-08-24 00:40:03.187',NULL,'comment_read','comment','read','查看评论',1),(23,'2025-08-24 00:40:03.187','2025-08-24 00:40:03.187',NULL,'comment_create','comment','create','创建评论',1),(24,'2025-08-24 00:40:03.188','2025-08-24 00:40:03.188',NULL,'comment_update','comment','update','更新评论',1),(25,'2025-08-24 00:40:03.188','2025-08-24 00:40:03.188',NULL,'comment_delete','comment','delete','删除评论',1),(26,'2025-08-24 00:40:03.189','2025-08-24 00:40:03.189',NULL,'comment_moderate','comment','moderate','审核评论',1),(27,'2025-08-24 00:40:03.189','2025-08-24 00:40:03.189',NULL,'tag_read','tag','read','查看标签',1),(28,'2025-08-24 00:40:03.190','2025-08-24 00:40:03.190',NULL,'tag_create','tag','create','创建标签',1),(29,'2025-08-24 00:40:03.190','2025-08-24 00:40:03.190',NULL,'tag_update','tag','update','更新标签',1),(30,'2025-08-24 00:40:03.191','2025-08-24 00:40:03.191',NULL,'tag_delete','tag','delete','删除标签',1),(31,'2025-08-24 00:40:03.191','2025-08-24 00:40:03.191',NULL,'role_read','role','read','查看角色',1),(32,'2025-08-24 00:40:03.192','2025-08-24 00:40:03.192',NULL,'role_create','role','create','创建角色',1),(33,'2025-08-24 00:40:03.192','2025-08-24 00:40:03.192',NULL,'role_update','role','update','更新角色',1),(34,'2025-08-24 00:40:03.193','2025-08-24 00:40:03.193',NULL,'role_delete','role','delete','删除角色',1),(35,'2025-08-24 00:40:03.193','2025-08-24 00:40:03.193',NULL,'permission_read','permission','read','查看权限',1),(36,'2025-08-24 00:40:03.193','2025-08-24 00:40:03.193',NULL,'permission_create','permission','create','创建权限',1),(37,'2025-08-24 00:40:03.194','2025-08-24 00:40:03.194',NULL,'permission_update','permission','update','更新权限',1),(38,'2025-08-24 00:40:03.194','2025-08-24 00:40:03.194',NULL,'permission_delete','permission','delete','删除权限',1),(39,'2025-08-24 00:40:03.195','2025-08-24 00:40:03.195',NULL,'route_read','route','read','查看路由',1),(40,'2025-08-24 00:40:03.196','2025-08-24 00:40:03.196',NULL,'route_create','route','create','创建路由',1),(41,'2025-08-24 00:40:03.196','2025-08-24 00:40:03.196',NULL,'route_update','route','update','更新路由',1),(42,'2025-08-24 00:40:03.197','2025-08-24 00:40:03.197',NULL,'route_delete','route','delete','删除路由',1),(43,NULL,NULL,NULL,'dashboard_read','dashboard','read','查看仪表板',1),(44,NULL,NULL,NULL,'dashboard_write','dashboard','write','编辑仪表板',1),(45,NULL,NULL,NULL,'app_config_read','app_config','read','查看应用配置',1),(46,NULL,NULL,NULL,'app_config_create','app_config','create','创建应用配置',1),(47,NULL,NULL,NULL,'app_config_update','app_config','update','更新应用配置',1),(48,NULL,NULL,NULL,'app_config_delete','app_config','delete','删除应用配置',1),(49,NULL,NULL,NULL,'menu_view','system:menu','view','查看菜单',1),(50,NULL,NULL,NULL,'menu_create','system:menu','create','创建菜单',1),(51,NULL,NULL,NULL,'menu_update','system:menu','update','更新菜单',1),(52,NULL,NULL,NULL,'menu_delete','system:menu','delete','删除菜单',1);
/*!40000 ALTER TABLE `permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_tags`
--

DROP TABLE IF EXISTS `post_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_tags` (
  `tag_id` bigint unsigned NOT NULL,
  `post_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`tag_id`,`post_id`),
  KEY `fk_post_tags_post` (`post_id`),
  CONSTRAINT `fk_post_tags_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`),
  CONSTRAINT `fk_post_tags_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_tags`
--

LOCK TABLES `post_tags` WRITE;
/*!40000 ALTER TABLE `post_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `post_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posts`
--

DROP TABLE IF EXISTS `posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `content` longtext COLLATE utf8mb4_unicode_ci,
  `summary` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `author_id` bigint unsigned NOT NULL,
  `published` tinyint(1) DEFAULT '0',
  `can_comment` tinyint(1) DEFAULT '1',
  `view_count` bigint DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_posts_slug` (`slug`),
  KEY `idx_posts_deleted_at` (`deleted_at`),
  KEY `fk_users_posts` (`author_id`),
  CONSTRAINT `fk_users_posts` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posts`
--

LOCK TABLES `posts` WRITE;
/*!40000 ALTER TABLE `posts` DISABLE KEYS */;
/*!40000 ALTER TABLE `posts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_assignments`
--

DROP TABLE IF EXISTS `role_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_assignments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `user_group_id` bigint unsigned DEFAULT NULL,
  `role_id` bigint unsigned DEFAULT NULL,
  `scope` longtext COLLATE utf8mb4_unicode_ci,
  `assigned_by` bigint unsigned DEFAULT NULL,
  `assigned_at` datetime(3) DEFAULT NULL,
  `expires_at` datetime(3) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_role_assignments_deleted_at` (`deleted_at`),
  KEY `fk_role_assignments_user` (`user_id`),
  KEY `fk_role_assignments_user_group` (`user_group_id`),
  KEY `fk_role_assignments_role` (`role_id`),
  CONSTRAINT `fk_role_assignments_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`),
  CONSTRAINT `fk_role_assignments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_role_assignments_user_group` FOREIGN KEY (`user_group_id`) REFERENCES `user_groups` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_assignments`
--

LOCK TABLES `role_assignments` WRITE;
/*!40000 ALTER TABLE `role_assignments` DISABLE KEYS */;
/*!40000 ALTER TABLE `role_assignments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role_permissions`
--

DROP TABLE IF EXISTS `role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permissions` (
  `role_id` bigint unsigned NOT NULL,
  `permission_id` bigint unsigned NOT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`role_id`,`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role_permissions`
--

LOCK TABLES `role_permissions` WRITE;
/*!40000 ALTER TABLE `role_permissions` DISABLE KEYS */;
INSERT INTO `role_permissions` VALUES (1,1,NULL),(1,2,NULL),(1,3,NULL),(1,4,NULL),(1,5,NULL),(1,6,NULL),(1,7,NULL),(1,8,NULL),(1,9,NULL),(1,10,NULL),(1,11,NULL),(1,12,NULL),(1,13,NULL),(1,14,NULL),(1,15,NULL),(1,16,NULL),(1,17,NULL),(1,18,NULL),(1,19,NULL),(1,20,NULL),(1,21,NULL),(1,22,NULL),(1,23,NULL),(1,24,NULL),(1,25,NULL),(1,26,NULL),(1,27,NULL),(1,28,NULL),(1,29,NULL),(1,30,NULL),(1,31,NULL),(1,32,NULL),(1,33,NULL),(1,34,NULL),(1,35,NULL),(1,36,NULL),(1,37,NULL),(1,38,NULL),(1,39,NULL),(1,40,NULL),(1,41,NULL),(1,42,NULL),(1,43,NULL),(1,44,NULL),(1,45,NULL),(1,46,NULL),(1,47,NULL),(1,48,NULL),(1,49,NULL),(1,50,NULL),(1,51,NULL),(1,52,NULL),(3,1,NULL),(3,3,NULL),(3,5,NULL),(3,6,NULL),(3,7,NULL),(3,22,NULL),(3,23,NULL),(3,24,NULL),(3,27,NULL),(4,1,NULL),(4,2,NULL),(4,3,NULL),(4,5,NULL),(4,6,NULL),(4,7,NULL),(4,8,NULL),(4,12,NULL),(4,13,NULL),(4,14,NULL),(4,15,NULL),(4,16,NULL),(4,17,NULL),(4,18,NULL),(4,19,NULL),(4,20,NULL),(4,21,NULL),(4,22,NULL),(4,23,NULL),(4,24,NULL),(4,25,NULL),(4,26,NULL),(4,27,NULL),(4,28,NULL),(4,29,NULL),(4,30,NULL),(4,31,NULL),(4,32,NULL),(4,33,NULL),(4,35,NULL),(4,36,NULL),(4,37,NULL),(4,39,NULL),(4,40,NULL),(4,41,NULL),(5,1,NULL),(5,2,NULL),(5,3,NULL),(5,5,NULL),(5,6,NULL),(5,7,NULL),(5,14,NULL),(5,15,NULL),(5,16,NULL),(5,17,NULL),(5,18,NULL),(5,19,NULL),(5,20,NULL),(5,21,NULL),(5,22,NULL),(5,23,NULL),(5,24,NULL),(5,25,NULL),(5,26,NULL),(5,27,NULL),(5,28,NULL),(5,29,NULL),(5,30,NULL),(5,39,NULL),(6,1,NULL),(6,3,NULL),(6,5,NULL),(6,6,NULL),(6,7,NULL),(6,16,NULL),(6,17,NULL),(6,18,NULL),(6,19,NULL),(6,20,NULL),(6,21,NULL),(6,22,NULL),(6,23,NULL),(6,24,NULL),(6,25,NULL),(6,26,NULL),(6,27,NULL),(6,28,NULL),(6,29,NULL),(6,39,NULL),(7,1,NULL),(7,5,NULL),(7,6,NULL),(7,7,NULL),(7,18,NULL),(7,19,NULL),(7,20,NULL),(7,21,NULL),(7,22,NULL),(7,23,NULL),(7,24,NULL),(7,25,NULL),(7,26,NULL),(7,27,NULL),(7,28,NULL),(7,29,NULL),(7,39,NULL),(8,5,NULL),(8,6,NULL),(8,7,NULL),(8,22,NULL),(8,23,NULL),(8,24,NULL),(8,27,NULL),(8,28,NULL),(8,29,NULL),(9,5,NULL),(9,21,NULL),(9,22,NULL),(9,26,NULL),(9,27,NULL),(10,5,NULL),(10,22,NULL),(10,27,NULL);
/*!40000 ALTER TABLE `role_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_roles_name` (`name`),
  KEY `idx_roles_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'2025-08-24 00:40:02.706','2025-08-24 00:40:03.198',NULL,'super_admin','超级管理员',1),(2,'2025-08-24 00:40:02.707','2025-08-24 00:40:02.707',NULL,'admin','管理员',1),(3,'2025-08-24 00:40:02.707','2025-08-24 00:40:03.210',NULL,'user','普通用户',1),(4,'2025-08-24 00:40:03.167','2025-08-24 00:40:03.200',NULL,'tenant_admin','租户管理员，拥有租户内所有权限',1),(5,'2025-08-24 00:40:03.168','2025-08-24 00:40:03.202',NULL,'org_admin','组织管理员，拥有组织内管理权限',1),(6,'2025-08-24 00:40:03.169','2025-08-24 00:40:03.204',NULL,'dept_manager','部门经理，拥有部门内管理权限',1),(7,'2025-08-24 00:40:03.170','2025-08-24 00:40:03.206',NULL,'project_lead','项目负责人，拥有项目管理权限',1),(8,'2025-08-24 00:40:03.170','2025-08-24 00:40:03.208',NULL,'content_editor','内容编辑，拥有内容管理权限',1),(9,'2025-08-24 00:40:03.171','2025-08-24 00:40:03.209',NULL,'content_reviewer','内容审核，拥有内容审核权限',1),(10,'2025-08-24 00:40:03.172','2025-08-24 00:40:03.211',NULL,'guest','访客，只有查看权限',1);
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `route_permissions`
--

DROP TABLE IF EXISTS `route_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `route_permissions` (
  `route_id` bigint unsigned NOT NULL,
  `permission_id` bigint unsigned NOT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`route_id`,`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `route_permissions`
--

LOCK TABLES `route_permissions` WRITE;
/*!40000 ALTER TABLE `route_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `route_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `routes`
--

DROP TABLE IF EXISTS `routes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `routes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `method` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `handler` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `middleware` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) DEFAULT '1',
  `sort_order` bigint DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_routes_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=96 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `routes`
--

LOCK TABLES `routes` WRITE;
/*!40000 ALTER TABLE `routes` DISABLE KEYS */;
INSERT INTO `routes` VALUES (45,'2025-08-24 09:38:25.381','2025-08-24 09:38:25.381',NULL,'博客首页','/','GET','BlogController.Index','','博客首页',1,1),(46,'2025-08-24 09:38:25.381','2025-08-24 09:38:25.381',NULL,'登录页面','/login','GET','AuthController.LoginPage','','用户登录页面',1,2),(47,'2025-08-24 09:38:25.381','2025-08-24 09:38:25.381',NULL,'管理后台','/admin','GET','AdminController.Dashboard','','管理后台首页',1,3),(48,'2025-08-24 09:38:25.382','2025-08-24 10:30:21.264',NULL,'路由管理页面','/api/admin/routes','GET','RouteController.Index','','路由管理页面',1,4),(49,'2025-08-24 09:38:25.382','2025-08-24 09:38:25.382',NULL,'文章详情页','/post/:id','GET','BlogController.GetPost','','文章详情页面',1,5),(50,'2025-08-24 09:38:25.382','2025-08-24 09:38:25.382',NULL,'健康检查','/health','GET','HealthController.Check','','系统健康检查',1,6),(51,'2025-08-24 09:38:25.382','2025-08-24 10:30:21.258',NULL,'用户登录','/api/auth/login','POST','AuthController.Login','','用户登录API',1,7),(52,'2025-08-24 09:38:25.383','2025-08-24 10:30:21.259',NULL,'用户注册','/api/auth/register','POST','AuthController.Register','','用户注册API',1,8),(53,'2025-08-24 09:38:25.383','2025-08-24 10:30:21.260',NULL,'用户登出','/api/auth/logout','POST','AuthController.Logout','Auth','用户登出API',1,9),(54,'2025-08-24 09:38:25.383','2025-08-24 10:30:21.261',NULL,'获取用户资料','/api/auth/profile','GET','AuthController.GetProfile','Auth','获取用户资料API',1,10),(55,'2025-08-24 09:38:25.383','2025-08-24 10:30:21.261',NULL,'更新用户资料','/api/auth/profile','PUT','AuthController.UpdateProfile','Auth','更新用户资料API',1,11),(56,'2025-08-24 09:38:25.384','2025-08-24 10:30:21.262',NULL,'修改密码','/api/auth/password','PUT','AuthController.ChangePassword','Auth','修改密码API',1,12),(57,'2025-08-24 09:38:25.384','2025-08-24 09:38:25.384',NULL,'获取文章列表','/blog/posts','GET','BlogController.GetPosts','','获取文章列表API',1,13),(58,'2025-08-24 09:38:25.384','2025-08-24 09:38:25.384',NULL,'获取热门文章','/blog/posts/popular','GET','BlogController.GetPopularPosts','','获取热门文章API',1,14),(59,'2025-08-24 09:38:25.385','2025-08-24 09:38:25.385',NULL,'搜索文章','/blog/posts/search','GET','BlogController.SearchPosts','','搜索文章API',1,15),(60,'2025-08-24 09:38:25.385','2025-08-24 09:38:25.385',NULL,'根据slug获取文章','/blog/posts/slug/:slug','GET','BlogController.GetPostBySlug','','根据slug获取文章API',1,16),(61,'2025-08-24 09:38:25.385','2025-08-24 09:38:25.385',NULL,'获取文章详情','/blog/posts/:id','GET','BlogController.GetPost','','获取文章详情API',1,17),(62,'2025-08-24 09:38:25.385','2025-08-24 09:38:25.385',NULL,'获取文章评论','/blog/posts/:id/comments','GET','BlogController.GetComments','','获取文章评论API',1,18),(63,'2025-08-24 09:38:25.386','2025-08-24 09:38:25.386',NULL,'获取所有标签','/blog/tags','GET','BlogController.GetAllTags','','获取所有标签API',1,19),(64,'2025-08-24 09:38:25.386','2025-08-24 09:38:25.386',NULL,'获取热门标签','/blog/tags/popular','GET','BlogController.GetPopularTags','','获取热门标签API',1,20),(65,'2025-08-24 09:38:25.386','2025-08-24 09:38:25.386',NULL,'创建文章','/blog/posts','POST','BlogController.CreatePost','Auth','创建文章API',1,21),(66,'2025-08-24 09:38:25.386','2025-08-24 09:38:25.386',NULL,'更新文章','/blog/posts/:id','PUT','BlogController.UpdatePost','Auth','更新文章API',1,22),(67,'2025-08-24 09:38:25.387','2025-08-24 09:38:25.387',NULL,'删除文章','/blog/posts/:id','DELETE','BlogController.DeletePost','Auth','删除文章API',1,23),(68,'2025-08-24 09:38:25.387','2025-08-24 09:38:25.387',NULL,'创建评论','/blog/posts/:id/comments','POST','BlogController.CreateComment','Auth','创建评论API',1,24),(69,'2025-08-24 09:38:25.387','2025-08-24 09:38:25.387',NULL,'创建菜单','/api/admin/menus','POST','MenuController.Create','auth,permission:system:menu:create','创建菜单API',1,25),(70,'2025-08-24 09:38:25.387','2025-08-24 09:38:25.387',NULL,'更新菜单','/api/admin/menus/:id','PUT','MenuController.Update','auth,permission:system:menu:update','更新菜单API',1,26),(71,'2025-08-24 09:38:25.388','2025-08-24 09:38:25.388',NULL,'删除菜单','/api/admin/menus/:id','DELETE','MenuController.Delete','auth,permission:system:menu:delete','删除菜单API',1,27),(72,'2025-08-24 09:38:25.388','2025-08-24 09:38:25.388',NULL,'获取菜单详情','/api/admin/menus/:id','GET','MenuController.GetByID','auth,permission:system:menu:view','获取菜单详情API',1,28),(73,'2025-08-24 09:38:25.389','2025-08-24 09:38:25.389',NULL,'获取菜单列表','/api/admin/menus','GET','MenuController.GetList','auth,permission:system:menu:view','获取菜单列表API',1,29),(74,'2025-08-24 09:38:25.390','2025-08-24 09:38:25.390',NULL,'获取菜单树','/api/admin/menus/tree','GET','MenuController.GetTree','auth,permission:system:menu:view','获取菜单树API',1,30),(75,'2025-08-24 09:38:25.391','2025-08-24 09:38:25.391',NULL,'获取导航菜单','/api/admin/menus/nav','GET','MenuController.Nav','auth','获取导航菜单API',1,31),(76,'2025-08-24 09:38:25.392','2025-08-24 09:38:25.392',NULL,'获取子菜单','/api/admin/menus/:id/children','GET','MenuController.GetChildren','auth,permission:system:menu:view','获取子菜单API',1,32),(77,'2025-08-24 09:38:25.392','2025-08-24 09:38:25.392',NULL,'获取父菜单','/api/admin/menus/:id/parent','GET','MenuController.GetParent','auth,permission:system:menu:view','获取父菜单API',1,33),(78,'2025-08-24 09:38:25.393','2025-08-24 09:38:25.393',NULL,'获取祖先菜单','/api/admin/menus/:id/ancestors','GET','MenuController.GetAncestors','auth,permission:system:menu:view','获取祖先菜单API',1,34),(79,'2025-08-24 09:38:25.394','2025-08-24 09:38:25.394',NULL,'获取后代菜单','/api/admin/menus/:id/descendants','GET','MenuController.GetDescendants','auth,permission:system:menu:view','获取后代菜单API',1,35),(80,'2025-08-24 09:38:25.394','2025-08-24 09:38:25.394',NULL,'根据应用获取菜单','/api/admin/menus/app/:app_id','GET','MenuController.GetByAppID','auth,permission:system:menu:view','根据应用获取菜单API',1,36),(81,'2025-08-24 09:38:25.395','2025-08-24 09:38:25.395',NULL,'根据模型获取菜单','/api/admin/menus/model/:model_id','GET','MenuController.GetByModelID','auth,permission:system:menu:view','根据模型获取菜单API',1,37),(82,'2025-08-24 09:38:25.396','2025-08-24 09:38:25.396',NULL,'批量更新菜单排序','/api/admin/menus/sort','PUT','MenuController.BatchUpdateSort','auth,permission:system:menu:update','批量更新菜单排序API',1,38),(83,'2025-08-24 09:38:25.396','2025-08-24 09:38:25.396',NULL,'获取菜单信息','/api/admin/menus/:id/info','GET','MenuController.GetMenuInfo','auth,permission:system:menu:view','获取菜单信息API',1,39),(84,'2025-08-24 10:41:14.050','2025-08-24 10:41:14.050',NULL,'仪表板统计','/api/admin/dashboard/stats','GET','AdminController.DashboardStats','','获取仪表板统计数据API',1,100),(85,NULL,NULL,NULL,'菜单管理','/admin/menus','GET','AdminController.Menus','auth,permission:system:menu:view','菜单管理页面',1,50),(86,NULL,NULL,NULL,'应用配置','/admin/app_config','GET','AdminController.AppConfig','auth,permission:app_config:read','应用配置页面',1,51),(87,NULL,NULL,NULL,'系统管理','/admin/system','GET','AdminController.System','auth,permission:system:config','系统管理页面',1,52),(88,NULL,NULL,NULL,'获取应用列表','/api/admin/app_config','GET','AppConfigController.GetAppList','auth,permission:app_config:read','获取应用列表API',1,60),(89,NULL,NULL,NULL,'创建应用','/api/admin/app_config','POST','AppConfigController.CreateApp','auth,permission:app_config:create','创建应用API',1,61),(90,NULL,NULL,NULL,'更新应用','/api/admin/app_config/:id','PUT','AppConfigController.UpdateApp','auth,permission:app_config:update','更新应用API',1,62),(91,NULL,NULL,NULL,'删除应用','/api/admin/app_config/:id','DELETE','AppConfigController.DeleteApp','auth,permission:app_config:delete','删除应用API',1,63),(92,NULL,NULL,NULL,'获取系统设置','/api/admin/system/settings','GET','SystemController.GetSettings','auth,permission:system:config','获取系统设置API',1,70),(93,NULL,NULL,NULL,'更新系统设置','/api/admin/system/settings','PUT','SystemController.UpdateSettings','auth,permission:system:config','更新系统设置API',1,71),(94,NULL,NULL,NULL,'创建备份','/api/admin/system/backup','POST','SystemController.CreateBackup','auth,permission:system:backup','创建备份API',1,72),(95,NULL,NULL,NULL,'获取备份列表','/api/admin/system/backups','GET','SystemController.GetBackups','auth,permission:system:backup','获取备份列表API',1,73);
/*!40000 ALTER TABLE `routes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scopes`
--

DROP TABLE IF EXISTS `scopes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scopes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `level` bigint NOT NULL,
  `parent_id` bigint unsigned DEFAULT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_scopes_name` (`name`),
  KEY `idx_scopes_deleted_at` (`deleted_at`),
  KEY `fk_scopes_children` (`parent_id`),
  CONSTRAINT `fk_scopes_children` FOREIGN KEY (`parent_id`) REFERENCES `scopes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scopes`
--

LOCK TABLES `scopes` WRITE;
/*!40000 ALTER TABLE `scopes` DISABLE KEYS */;
INSERT INTO `scopes` VALUES (1,'2025-08-24 00:40:03.163','2025-08-24 00:40:03.163',NULL,'system',1,NULL,'系统级范围',1),(2,'2025-08-24 00:40:03.164','2025-08-24 00:40:03.164',NULL,'tenant',2,NULL,'租户级范围',1),(3,'2025-08-24 00:40:03.164','2025-08-24 00:40:03.164',NULL,'organization',3,NULL,'组织级范围',1),(4,'2025-08-24 00:40:03.165','2025-08-24 00:40:03.165',NULL,'department',4,NULL,'部门级范围',1),(5,'2025-08-24 00:40:03.166','2025-08-24 00:40:03.166',NULL,'project',5,NULL,'项目级范围',1);
/*!40000 ALTER TABLE `scopes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `color` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT '#007bff',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_tags_name` (`name`),
  UNIQUE KEY `uni_tags_slug` (`slug`),
  KEY `idx_tags_deleted_at` (`deleted_at`)
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
-- Table structure for table `temporary_permissions`
--

DROP TABLE IF EXISTS `temporary_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `temporary_permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `resource` longtext COLLATE utf8mb4_unicode_ci,
  `action` longtext COLLATE utf8mb4_unicode_ci,
  `granted_by` bigint unsigned DEFAULT NULL,
  `granted_at` datetime(3) DEFAULT NULL,
  `expires_at` datetime(3) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auto_revoke` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `idx_temporary_permissions_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `temporary_permissions`
--

LOCK TABLES `temporary_permissions` WRITE;
/*!40000 ALTER TABLE `temporary_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `temporary_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_group_members`
--

DROP TABLE IF EXISTS `user_group_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_group_members` (
  `user_id` bigint unsigned NOT NULL,
  `user_group_id` bigint unsigned NOT NULL,
  `joined_at` datetime(3) DEFAULT NULL,
  `expires_at` datetime(3) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`user_id`,`user_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_group_members`
--

LOCK TABLES `user_group_members` WRITE;
/*!40000 ALTER TABLE `user_group_members` DISABLE KEYS */;
INSERT INTO `user_group_members` VALUES (1,1,NULL,NULL,1);
/*!40000 ALTER TABLE `user_group_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_groups`
--

DROP TABLE IF EXISTS `user_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `scope` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT 'system',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_user_groups_name` (`name`),
  KEY `idx_user_groups_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_groups`
--

LOCK TABLES `user_groups` WRITE;
/*!40000 ALTER TABLE `user_groups` DISABLE KEYS */;
INSERT INTO `user_groups` VALUES (1,'2025-08-24 00:40:03.173','2025-08-24 00:40:03.250',NULL,'system_administrators','系统管理员组',1,'system'),(2,'2025-08-24 00:40:03.174','2025-08-24 00:40:03.215',NULL,'tenant_administrators','租户管理员组',1,'tenant'),(3,'2025-08-24 00:40:03.175','2025-08-24 00:40:03.216',NULL,'content_team','内容团队组',1,'organization'),(4,'2025-08-24 00:40:03.175','2025-08-24 00:40:03.217',NULL,'development_team','开发团队组',1,'department'),(5,'2025-08-24 00:40:03.176','2025-08-24 00:40:03.218',NULL,'qa_team','测试团队组',1,'department'),(6,'2025-08-24 00:40:03.177','2025-08-24 00:40:03.219',NULL,'regular_users','普通用户组',1,'organization');
/*!40000 ALTER TABLE `user_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_roles`
--

DROP TABLE IF EXISTS `user_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_roles` (
  `user_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`user_id`,`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES (1,1,'2025-08-24 00:40:02.766');
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `username` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nickname` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bio` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `is_super` tinyint(1) DEFAULT '0',
  `last_login_at` timestamp NULL DEFAULT NULL,
  `last_login_ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_users_username` (`username`),
  UNIQUE KEY `uni_users_email` (`email`),
  KEY `idx_users_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'2025-08-24 00:40:02.765','2025-08-24 11:41:42.356',NULL,'admin','admin@looma.com','$2a$10$jkl9woAb05NR7e6wJ22VIOJqH90b64bbb2n3lawif6RCz12QN2pVa','超级管理员','','',1,1,'2025-08-24 03:41:42','::1');
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

-- Dump completed on 2025-08-29 20:50:18
