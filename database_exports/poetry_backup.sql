-- MySQL dump 10.13  Distrib 9.4.0, for macos15.4 (arm64)
--
-- Host: localhost    Database: poetry
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
-- Table structure for table `about_me`
--

DROP TABLE IF EXISTS `about_me`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `about_me` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `github` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `weibo` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `git_hub` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `about_me`
--

LOCK TABLES `about_me` WRITE;
/*!40000 ALTER TABLE `about_me` DISABLE KEYS */;
INSERT INTO `about_me` VALUES (1,'Poetry Blogger','热爱技术，热爱生活，记录成长的点滴。专注于Go语言、Web开发和系统架构。','poetry@example.com','https://github.com/poetry','https://weibo.com/poetry',NULL,'2025-08-24 08:06:12','2025-08-24 12:15:25',NULL);
/*!40000 ALTER TABLE `about_me` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `git_hub_id` bigint DEFAULT NULL,
  `post_id` bigint DEFAULT NULL,
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `ref_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
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
-- Table structure for table `git_hub_users`
--

DROP TABLE IF EXISTS `git_hub_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `git_hub_users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `g_id` bigint DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `picture` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nick_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uix_git_hub_users_g_id` (`g_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `git_hub_users`
--

LOCK TABLES `git_hub_users` WRITE;
/*!40000 ALTER TABLE `git_hub_users` DISABLE KEYS */;
/*!40000 ALTER TABLE `git_hub_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `page_configs`
--

DROP TABLE IF EXISTS `page_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `page_configs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `page_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `config_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `config_value` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `page_configs`
--

LOCK TABLES `page_configs` WRITE;
/*!40000 ALTER TABLE `page_configs` DISABLE KEYS */;
INSERT INTO `page_configs` VALUES (1,'home','page_title','Poetry Blog - 首页','2025-08-24 08:44:26'),(2,'home','site_title','Poetry Blog','2025-08-24 08:44:26');
/*!40000 ALTER TABLE `page_configs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_tags`
--

DROP TABLE IF EXISTS `post_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `post_id` bigint DEFAULT NULL,
  `tag_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
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
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `author_id` int DEFAULT NULL,
  `slug` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `summary` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `can_comment` tinyint(1) DEFAULT NULL,
  `published` tinyint(1) DEFAULT NULL,
  `status` int DEFAULT '0',
  `type` int DEFAULT '0',
  `pageview` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uix_posts_title` (`title`),
  KEY `idx_posts_slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posts`
--

LOCK TABLES `posts` WRITE;
/*!40000 ALTER TABLE `posts` DISABLE KEYS */;
INSERT INTO `posts` VALUES (1,'2025-08-24 07:34:51','2025-08-24 07:34:51','欢迎来到我的博客',NULL,'welcome','这是我的第一篇博客文章。','这是我的第一篇博客文章。\n\n在这里，我将分享我的想法和经验。',NULL,1,0,0,0),(2,'2025-08-24 07:34:58','2025-08-24 07:34:58','关于技术分享',NULL,'tech-sharing','技术分享是学习的重要方式。','技术分享是学习的重要方式。\n\n通过分享，我们不仅可以巩固自己的知识，还能帮助他人。',NULL,1,0,0,0);
/*!40000 ALTER TABLE `posts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `react_items`
--

DROP TABLE IF EXISTS `react_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `react_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `post_id` bigint DEFAULT NULL,
  `reaction_type` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `react_items`
--

LOCK TABLES `react_items` WRITE;
/*!40000 ALTER TABLE `react_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `react_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `routes`
--

DROP TABLE IF EXISTS `routes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `routes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `path` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `template_file` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_source` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `auth_required` tinyint(1) DEFAULT '0',
  `permissions` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `path` (`path`)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `routes`
--

LOCK TABLES `routes` WRITE;
/*!40000 ALTER TABLE `routes` DISABLE KEYS */;
INSERT INTO `routes` VALUES (1,'/','front/index.html','home_data','2025-08-24 08:44:21',0,''),(2,'/api/tag/:id/posts','api/tag_posts','tag_posts_api_data','2025-08-24 10:28:53',0,''),(3,'/api/search','api/search','search_data','2025-08-24 10:28:53',0,NULL),(4,'/post/:id','front/post.html','post_detail_data','2025-08-24 15:22:34',0,''),(5,'/pages/:page','front/index.html','post_list_data','2025-08-24 15:22:34',0,''),(6,'/tags','front/tags.html','tags_list_data','2025-08-24 15:22:34',0,''),(7,'/tag/:id','front/tag.html','tag_posts_data','2025-08-24 15:22:34',0,''),(8,'/archives','front/archives.html','archives_data','2025-08-24 15:22:34',0,''),(9,'/archives/:year','front/archives.html','archives_by_year_data','2025-08-24 15:22:34',0,''),(10,'/activity','front/activity.html','activity_data','2025-08-24 15:22:34',0,''),(11,'/topics','front/topics.html','topics_data','2025-08-24 15:22:34',0,''),(12,'/favorites','front/favorites.html','favorites_data','2025-08-24 15:22:34',0,''),(13,'/search','front/search.html','search_page_data','2025-08-24 15:22:34',0,''),(14,'/page/:aboutme','front/post.html','about_me_data','2025-08-24 15:22:34',0,''),(15,'/comments/post/:id','front/comment.html','comments_data','2025-08-24 15:22:34',1,'user'),(16,'/rss','front/rss.html','rss_data','2025-08-24 15:22:34',0,''),(17,'/admin/login','admin/login.html','admin_login_data','2025-08-24 15:22:34',0,''),(18,'/admin/','admin/index.html','admin_dashboard_data','2025-08-24 15:22:34',1,'admin'),(19,'/admin/posts','admin/list_post.html','admin_posts_list_data','2025-08-24 15:22:34',1,'admin'),(20,'/admin/post/new','admin/post.html','admin_post_new_data','2025-08-24 15:22:34',1,'admin'),(21,'/admin/post/edit/:id','admin/post.html','admin_post_edit_data','2025-08-24 15:22:34',1,'admin'),(22,'/admin/post/preview/:id','front/post.html','admin_post_preview_data','2025-08-24 15:22:34',1,'admin'),(23,'/admin/posts/page/:page','admin/list_post.html','admin_posts_paged_data','2025-08-24 15:22:34',1,'admin'),(24,'/admin/users','admin/list_user.html','admin_users_list_data','2025-08-24 15:22:34',1,'admin'),(25,'/admin/user/new','admin/user.html','admin_user_new_data','2025-08-24 15:22:34',1,'admin'),(26,'/admin/user/edit/:id','admin/user.html','admin_user_edit_data','2025-08-24 15:22:34',1,'admin'),(27,'/admin/users/page/:page','admin/list_user.html','admin_users_paged_data','2025-08-24 15:22:34',1,'admin'),(28,'/admin/tags','admin/list_tag.html','admin_tags_list_data','2025-08-24 15:22:34',1,'admin'),(29,'/admin/tag/new','admin/tag.html','admin_tag_new_data','2025-08-24 15:22:34',1,'admin'),(30,'/admin/tag/edit/:id','admin/tag.html','admin_tag_edit_data','2025-08-24 15:22:34',1,'admin'),(31,'/admin/comments','admin/list_comment.html','admin_comments_list_data','2025-08-24 15:22:34',1,'admin'),(32,'/admin/upload','admin/upload.html','admin_upload_data','2025-08-24 15:22:34',1,'admin'),(33,'/admin/about-me','admin/about_me.html','admin_about_me_data','2025-08-24 15:22:34',1,'admin'),(34,'/json/search','api/search','search_api_data','2025-08-24 15:22:34',0,'');
/*!40000 ALTER TABLE `routes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tags`
--

LOCK TABLES `tags` WRITE;
/*!40000 ALTER TABLE `tags` DISABLE KEYS */;
INSERT INTO `tags` VALUES (1,'2025-08-24 06:39:21','2025-08-24 06:39:21','诗人地图');
/*!40000 ALTER TABLE `tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `templates`
--

DROP TABLE IF EXISTS `templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `templates` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `templates`
--

LOCK TABLES `templates` WRITE;
/*!40000 ALTER TABLE `templates` DISABLE KEYS */;
INSERT INTO `templates` VALUES (1,'admin/login.html','{{ define \"admin/login.html\" }}\n    <!DOCTYPE html>\n    <html lang=\"en\">\n    <head>\n        <meta charset=\"UTF-8\">\n        <meta name=\"error\" content=\"{{.msg}}\">\n        <title>管理后台</title>\n        <link rel=\"stylesheet\" href=\"/static/css/uikit.min.css\" />\n    </head>\n    <body>\n        <div class=\"uk-height-1-1 uk-flex uk-flex-center uk-flex-middle\" style=\"background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);\">\n            <div class=\"uk-width-1-3@m uk-width-1-2@s\">\n                <div class=\"uk-card uk-card-default uk-card-body uk-box-shadow-large\" style=\"border-radius: 10px;\">\n                    <div class=\"uk-text-center uk-margin-medium-bottom\">\n                        <h2 class=\"uk-card-title\" style=\"color: #333; margin-bottom: 10px;\">管理后台登录</h2>\n                        <p class=\"uk-text-meta\" style=\"color: #666;\">请输入您的登录信息</p>\n                    </div>\n                    \n                    <form action=\"/admin/login\" method=\"POST\" name=\"login_user_form\">\n                        <div class=\"uk-margin\">\n                            <label class=\"uk-form-label\" for=\"username\" style=\"color: #333; font-weight: 500;\">用户名</label>\n                            <div class=\"uk-form-controls\">\n                                <input name=\"username\" id=\"username\" class=\"uk-input\" type=\"text\" placeholder=\"请输入用户名\" style=\"border-radius: 5px; border: 1px solid #ddd;\">\n                            </div>\n                        </div>\n                        \n                        <div class=\"uk-margin\">\n                            <label class=\"uk-form-label\" for=\"password\" style=\"color: #333; font-weight: 500;\">密码</label>\n                            <div class=\"uk-form-controls\">\n                                <input name=\"password\" id=\"password\" class=\"uk-input\" type=\"password\" placeholder=\"请输入密码\" style=\"border-radius: 5px; border: 1px solid #ddd;\">\n                            </div>\n                        </div>\n                        \n                        {{if .msg}}\n                        <div class=\"uk-margin\">\n                            <div class=\"uk-alert uk-alert-danger\" style=\"border-radius: 5px;\">\n                                <p class=\"uk-margin-remove\">{{.msg}}</p>\n                            </div>\n                        </div>\n                        {{end}}\n                        \n                        <div class=\"uk-margin uk-text-center\">\n                            <button class=\"uk-button uk-button-primary uk-button-large\" style=\"border-radius: 5px; min-width: 120px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);\">\n                                登录\n                            </button>\n                        </div>\n                    </form>\n                </div>\n            </div>\n        </div>\n        \n        <script src=\"https://cdn.bootcss.com/jquery/3.4.1/jquery.js\"></script>\n        <script src=\"/static/dist/base.js\"></script>\n        <script src=\"/static/dist/admin.js\"></script>\n\n    </body>\n    </html>\n\n{{end}}','2025-08-24 12:27:12','2025-08-24 12:27:12');
/*!40000 ALTER TABLE `templates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `intro` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pass_word` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `git_hub_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT 'user',
  `subsystem` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT 'libai',
  `global_user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uix_users_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'2025-08-24 04:04:37','2025-08-24 04:04:37','系统管理员','admin@example.com','admin','e10adc3949ba59abbe56e057f20f883e',NULL,1,'e10adc3949ba59abbe56e057f20f883e',NULL,'user','libai',NULL),(2,'2025-08-24 06:37:03','2025-08-24 06:37:03','','szpeter@poetry.com','szpeter',NULL,NULL,1,'86c0d431c06f5b309417ab26d082165c','','user','libai',NULL);
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

-- Dump completed on 2025-08-29 20:50:30
