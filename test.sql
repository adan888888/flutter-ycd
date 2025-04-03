/*
 Navicat Premium Dump SQL

 Source Server         : docker-mysql
 Source Server Type    : MySQL
 Source Server Version : 90100 (9.1.0)
 Source Host           : 127.0.0.1:3306
 Source Schema         : test

 Target Server Type    : MySQL
 Target Server Version : 90100 (9.1.0)
 File Encoding         : 65001

 Date: 03/04/2025 20:29:18
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for articles
-- ----------------------------
DROP TABLE IF EXISTS `articles`;
CREATE TABLE `articles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `preview` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------
-- Records of articles
-- ----------------------------
BEGIN;
INSERT INTO `articles` (`id`, `title`, `content`, `preview`, `created_at`, `updated_at`, `deleted_at`) VALUES (9, '这', '美元升值了3', '行情越来越来了3', '2024-10-25 16:05:39.779', '2024-10-25 16:05:39.779', NULL);
INSERT INTO `articles` (`id`, `title`, `content`, `preview`, `created_at`, `updated_at`, `deleted_at`) VALUES (10, '这', '美元升值了3', '行情越来越来了3', '2024-10-25 16:07:34.163', '2024-10-25 16:07:34.163', NULL);
INSERT INTO `articles` (`id`, `title`, `content`, `preview`, `created_at`, `updated_at`, `deleted_at`) VALUES (13, '行情来了', '美元升值了333333', '行情越来越来了3444', '2024-11-18 17:56:33.378', '2024-11-18 17:56:33.378', NULL);
INSERT INTO `articles` (`id`, `title`, `content`, `preview`, `created_at`, `updated_at`, `deleted_at`) VALUES (14, '行情来了', '美元升值了66', '行情越来越好，迅速加仓', '2024-11-18 17:57:54.095', '2024-11-18 17:57:54.095', NULL);
COMMIT;

-- ----------------------------
-- Table structure for authors
-- ----------------------------
DROP TABLE IF EXISTS `authors`;
CREATE TABLE `authors` (
  `a_id` int NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `age` int DEFAULT NULL,
  `sex` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`a_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------
-- Records of authors
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for banners
-- ----------------------------
DROP TABLE IF EXISTS `banners`;
CREATE TABLE `banners` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------
-- Records of banners
-- ----------------------------
BEGIN;
INSERT INTO `banners` (`ID`, `url`) VALUES (1, 'https://images.hibigwin.com/9f/202404/DDnZEhXKutDVIYn.jpg');
INSERT INTO `banners` (`ID`, `url`) VALUES (2, 'https://images.hibigwin.com/9fnew/202407/HyEelbrkIZOxoCC.jpg');
INSERT INTO `banners` (`ID`, `url`) VALUES (3, 'https://images.hibigwin.com/9fnew/202411/yFhDuIBrLQTooVd.jpg');
INSERT INTO `banners` (`ID`, `url`) VALUES (4, 'https://images.hibigwin.com/9fnew/202411/FrPiilIBvbRQAJo.jpg');
INSERT INTO `banners` (`ID`, `url`) VALUES (5, 'https://images.hibigwin.com/9fnew/202409/rUENzexkidlKItF.jpg');
INSERT INTO `banners` (`ID`, `url`) VALUES (6, 'https://9f.com/images/ad/ADWheel02.jpg');
INSERT INTO `banners` (`ID`, `url`) VALUES (7, 'https://9f.com/images/ad/AD_Cashback02.jpg');
COMMIT;

-- ----------------------------
-- Table structure for students
-- ----------------------------
DROP TABLE IF EXISTS `students`;
CREATE TABLE `students` (
  `stu_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `age` int DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `sex` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`stu_id`)
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8mb3;

-- ----------------------------
-- Records of students
-- ----------------------------
BEGIN;
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (1, '张三', 18, 'xxxxx@gamil.com', '女');
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (2, '张三', 18, 'xxxxx@gamil.com', '女');
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (3, '张三经', 18, 'xxxxx@gamil.com', '女');
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (4, '张三', 18, 'xxxxx@gamil.com', '女');
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (5, '张三', 20, '36', '男');
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (6, '张三', 18, 'xxxxx@gamil.com', '女');
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (7, '张三', 18, 'xxxxx@gamil.com', '女');
INSERT INTO `students` (`stu_id`, `name`, `age`, `email`, `sex`) VALUES (8, '张三', 18, 'xxxxx@gamil.com', '女');
COMMIT;

-- ----------------------------
-- Table structure for table_yanchendao1
-- ----------------------------
DROP TABLE IF EXISTS `table_yanchendao1`;
CREATE TABLE `table_yanchendao1` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `column_benjin` varchar(255) NOT NULL COMMENT '''本金''',
  `column_yongjin` varchar(255) NOT NULL COMMENT '''俑金''',
  `column_mean` varchar(255) NOT NULL COMMENT '''数学期望''',
  `column_restart_index` varchar(255) NOT NULL COMMENT '''重起位置''',
  `column_liushui_index` varchar(255) NOT NULL COMMENT '''流水的位置''',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '''创建时间''',
  `uid` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_users_table_yanchendao1s` (`uid`),
  CONSTRAINT `fk_users_table_yanchendao1s` FOREIGN KEY (`uid`) REFERENCES `users` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------
-- Records of table_yanchendao1
-- ----------------------------
BEGIN;
INSERT INTO `table_yanchendao1` (`id`, `column_benjin`, `column_yongjin`, `column_mean`, `column_restart_index`, `column_liushui_index`, `created_at`, `uid`) VALUES (1, '5000', '0.95', '0.08', '0', '0', '2025-04-03 11:27:24', 1907650735441448960);
INSERT INTO `table_yanchendao1` (`id`, `column_benjin`, `column_yongjin`, `column_mean`, `column_restart_index`, `column_liushui_index`, `created_at`, `uid`) VALUES (2, '5000', '0.95', '0.08', '0', '0', '2025-04-03 11:27:24', 1852251920824012800);
COMMIT;

-- ----------------------------
-- Table structure for table_yanchendao2
-- ----------------------------
DROP TABLE IF EXISTS `table_yanchendao2`;
CREATE TABLE `table_yanchendao2` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `column_xiazhujine` varchar(255) NOT NULL COMMENT '''下注的金额''',
  `colmun_shuyingzhi` varchar(255) NOT NULL COMMENT '''输赢值''',
  `colmun_shuyingzhi_d` varchar(255) NOT NULL COMMENT '''消数后的输赢值''',
  `colmun_shengfulu` varchar(10) NOT NULL COMMENT '''胜负路（输赢标记）''',
  `colmun_zx` varchar(10) NOT NULL COMMENT '''开出的是庄还是闲''',
  `colmun_remark` varchar(255) DEFAULT NULL COMMENT '''输赢标记备注''',
  `column_current_jin` varchar(255) NOT NULL COMMENT '''当前的钱''',
  `column_refresh` tinyint(1) DEFAULT '0' COMMENT '''用来刷新用''',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '''创建时间''',
  `user_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_users_table_yanchendao2s` (`user_id`),
  CONSTRAINT `fk_users_table_yanchendao2s` FOREIGN KEY (`user_id`) REFERENCES `users` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------
-- Records of table_yanchendao2
-- ----------------------------
-- BEGIN;
-- INSERT INTO `table_yanchendao2` (`id`, `column_xiazhujine`, `colmun_shuyingzhi`, `colmun_shuyingzhi_d`, `colmun_shengfulu`, `colmun_zx`, `colmun_remark`, `column_current_jin`, `column_refresh`, `created_at`, `user_id`) VALUES (1, '1', '0.95', '0.95', '反打', '闲', '1', '5054.349999999999', 0, '2025-04-03 11:17:50', 1907650735441448960);
-- INSERT INTO `table_yanchendao2` (`id`, `column_xiazhujine`, `colmun_shuyingzhi`, `colmun_shuyingzhi_d`, `colmun_shengfulu`, `colmun_zx`, `colmun_remark`, `column_current_jin`, `column_refresh`, `created_at`, `user_id`) VALUES (2, '1', '0.95', '0.95', '反打', '闲', '1', '5055.299999999999', 0, '2025-04-03 11:20:41', 1907650735441448960);
-- COMMIT;

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `username` varchar(191) DEFAULT NULL,
  `password` longtext,
  `uid` bigint DEFAULT NULL,
  `token` longtext,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_users_username` (`username`),
  UNIQUE KEY `uni_users_uid` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------
-- Records of users
-- ----------------------------
BEGIN;
INSERT INTO `users` (`id`, `created_at`, `updated_at`, `username`, `password`, `uid`, `token`) VALUES (1, '2024-11-01 11:30:45.793', '2024-11-01 11:30:45.793', 'admin1', '$2a$12$f464sjJxFeW4wpHALPW1Xe247.OmETr5zJB87BKNAkDef12yFKeDK', 1852251920824012800, NULL);
INSERT INTO `users` (`id`, `created_at`, `updated_at`, `username`, `password`, `uid`, `token`) VALUES (2, '2025-04-03 13:25:52.460', '2025-04-03 13:25:52.460', 'admin2', '$2a$12$VBlwuTUpCO0wqlxayYcSE.wC2ejSwBGW7NCDc0nTbuejzrTgr4hg2', 1907650735441448960, '');
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
