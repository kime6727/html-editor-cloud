-- HTML Code Editor - MySQL 5.7.44 完整初始化脚本
-- 版本: v3.0
-- 日期: 2026-05-16
-- 说明: 包含所有功能（发布、过期、密码保护、访问统计、临时链接、IP匿名化等）
-- 适用: MySQL 5.7.44

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `html_editor` 
  DEFAULT CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

USE `html_editor`;

-- =============================================
-- 1. 用户表
-- =============================================
CREATE TABLE `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(50) NOT NULL COMMENT '用户ID: usr_timestamp_random',
  `is_pro` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否Pro用户',
  `pro_activated_at` DATETIME DEFAULT NULL COMMENT 'Pro激活时间',
  `publish_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '发布次数',
  `total_visits` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总访问量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `last_active_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后活跃时间',
  `status` ENUM('active', 'banned', 'suspended') NOT NULL DEFAULT 'active' COMMENT '用户状态',
  `ban_reason` VARCHAR(255) DEFAULT NULL COMMENT '封禁原因',
  `banned_at` DATETIME DEFAULT NULL COMMENT '封禁时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `idx_is_pro` (`is_pro`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_last_active` (`last_active_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- =============================================
-- 2. 项目表
-- =============================================
CREATE TABLE `projects` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID',
  `project_name` VARCHAR(255) NOT NULL DEFAULT 'Untitled' COMMENT '项目名称',
  `user_id` VARCHAR(50) DEFAULT NULL COMMENT '关联用户ID',
  `is_pro` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '发布时是否Pro',
  `file_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '文件数量',
  `visit_count` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '访问次数',
  `status` ENUM('active', 'inactive', 'expired', 'deleted', 'banned') NOT NULL DEFAULT 'active' COMMENT '项目状态',
  `expire_days` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '过期天数(0=自定义分钟)',
  `expire_minutes` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '过期分钟数',
  `expires_at` DATETIME DEFAULT NULL COMMENT '过期时间(NULL=永久)',
  `access_password` VARCHAR(255) DEFAULT NULL COMMENT '访问密码(bcrypt加密)',
  `expired_redirect_type` ENUM('app_promotion', 'custom_url', 'custom_message') NOT NULL DEFAULT 'app_promotion' COMMENT '到期后重定向类型',
  `expired_redirect_url` VARCHAR(500) DEFAULT NULL COMMENT '到期后重定向URL',
  `expired_custom_message` TEXT DEFAULT NULL COMMENT '到期后自定义消息',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `last_visited_at` DATETIME DEFAULT NULL COMMENT '最后访问时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_id` (`project_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_is_pro` (`is_pro`),
  KEY `idx_status` (`status`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_visit_count` (`visit_count`),
  KEY `idx_user_status_created` (`user_id`, `status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目表';

-- =============================================
-- 3. 访问日志表（含IP匿名化）
-- =============================================
CREATE TABLE `visit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID',
  `ip_address` VARCHAR(45) NOT NULL COMMENT '访问IP(已匿名化)',
  `ip_hash` VARCHAR(16) DEFAULT NULL COMMENT 'IP地址哈希(匿名化)',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '浏览器UA',
  `referer` VARCHAR(500) DEFAULT NULL COMMENT '来源页面',
  `country` VARCHAR(50) DEFAULT NULL COMMENT '国家(可选)',
  `city` VARCHAR(50) DEFAULT NULL COMMENT '城市(可选)',
  `device_type` ENUM('mobile', 'tablet', 'desktop', 'unknown') DEFAULT 'unknown' COMMENT '设备类型',
  `visited_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '访问时间',
  PRIMARY KEY (`id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_visited_at` (`visited_at`),
  KEY `idx_ip_address` (`ip_address`),
  KEY `idx_ip_hash` (`ip_hash`),
  KEY `idx_device_type` (`device_type`),
  KEY `idx_project_device` (`project_id`, `device_type`),
  KEY `idx_project_referer` (`project_id`, `referer`(100)),
  KEY `idx_project_visited` (`project_id`, `visited_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='访问日志表';

-- =============================================
-- 4. 用户活动日志表
-- =============================================
CREATE TABLE `user_activity_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(50) NOT NULL COMMENT '用户ID',
  `project_id` VARCHAR(20) DEFAULT NULL COMMENT '关联项目',
  `action` ENUM('publish', 'update', 'delete', 'login', 'subscribe', 'unsubscribe') NOT NULL COMMENT '操作类型',
  `details` JSON DEFAULT NULL COMMENT '详细信息',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_user_action_created` (`user_id`, `action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户活动日志表';

-- =============================================
-- 5. 管理员操作日志表（含IP匿名化）
-- =============================================
CREATE TABLE `admin_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_user` VARCHAR(50) NOT NULL COMMENT '管理员账号',
  `action` VARCHAR(50) NOT NULL COMMENT '操作类型',
  `target_type` ENUM('user', 'project', 'system') NOT NULL COMMENT '目标类型',
  `target_id` VARCHAR(100) DEFAULT NULL COMMENT '目标ID',
  `details` JSON DEFAULT NULL COMMENT '详细信息',
  `ip_address` VARCHAR(45) NOT NULL COMMENT '管理员IP(已匿名化)',
  `ip_hash` VARCHAR(16) DEFAULT NULL COMMENT 'IP地址哈希(匿名化)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_admin_user` (`admin_user`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员操作日志表';

-- =============================================
-- 6. 统计缓存表
-- =============================================
CREATE TABLE `daily_stats` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `stat_date` DATE NOT NULL COMMENT '统计日期',
  `total_projects` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总项目数',
  `total_visits` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总访问量',
  `new_users` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '新用户数',
  `active_users` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '活跃用户数',
  `pro_users` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Pro用户数',
  `publish_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '发布次数',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stat_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='每日统计缓存表';

-- =============================================
-- 7. 系统配置表
-- =============================================
CREATE TABLE `system_config` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_key` VARCHAR(100) NOT NULL,
  `config_value` TEXT,
  `description` VARCHAR(255) DEFAULT NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 插入默认配置（免费用户1小时过期，启用所有功能）
INSERT INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('app_version', '3.0.0', '应用版本'),
('maintenance_mode', '0', '维护模式(0=关闭,1=开启)'),
('max_upload_size', '10485760', '最大上传大小(字节)'),
('free_user_expire_minutes', '60', '免费用户过期分钟数（1小时）'),
('default_domain', 'https://html.niceapp.eu.cc', '默认域名'),
('enable_realtime_expiry_check', '1', '启用实时过期检查（通过index.php网关）'),
('enable_password_protection', '1', '启用密码保护功能'),
('enable_visit_tracking', '1', '启用访问日志记录'),
('session_timeout_minutes', '60', '密码验证session有效期（分钟）'),
('temp_link_max_duration_hours', '168', '临时链接最大有效时长(小时)'),
('expired_redirect_enabled', '1', '是否启用到期重定向功能');

-- =============================================
-- 8. 订阅记录表
-- =============================================
CREATE TABLE `subscription_records` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(50) NOT NULL COMMENT '用户ID',
  `transaction_id` VARCHAR(100) DEFAULT NULL COMMENT 'Apple交易ID',
  `product_id` VARCHAR(100) NOT NULL COMMENT '产品ID',
  `status` ENUM('active', 'expired', 'refunded', 'cancelled') NOT NULL DEFAULT 'active',
  `purchased_at` DATETIME NOT NULL COMMENT '购买时间',
  `expires_at` DATETIME DEFAULT NULL COMMENT '过期时间',
  `refund_date` DATETIME DEFAULT NULL COMMENT '退款时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_transaction_id` (`transaction_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订阅记录表';

-- =============================================
-- 9. 临时访问链接表
-- =============================================
CREATE TABLE `temp_access_links` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID',
  `token` VARCHAR(64) NOT NULL COMMENT '临时访问token',
  `expires_at` DATETIME NOT NULL COMMENT '过期时间',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `used_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '使用次数',
  `last_used_at` DATETIME DEFAULT NULL COMMENT '最后使用时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_token` (`token`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='临时访问链接表';

-- =============================================
-- 视图：用户统计概览
-- =============================================
CREATE OR REPLACE VIEW `v_user_stats` AS
SELECT 
  u.id,
  u.user_id,
  u.is_pro,
  u.publish_count,
  u.total_visits,
  u.status,
  u.created_at,
  u.last_active_at,
  COUNT(DISTINCT p.id) as project_count,
  SUM(p.visit_count) as total_project_visits,
  MAX(p.created_at) as last_publish_at
FROM users u
LEFT JOIN projects p ON u.user_id = p.user_id AND p.status = 'active'
GROUP BY u.id;

-- =============================================
-- 视图：项目详细统计（含过期状态）
-- =============================================
CREATE OR REPLACE VIEW `v_project_stats` AS
SELECT 
  p.*,
  u.is_pro as user_is_pro,
  u.status as user_status,
  COUNT(DISTINCT CASE WHEN vl.visited_at >= CURDATE() THEN vl.id END) as today_visits,
  (SELECT COUNT(*) FROM visit_logs vl2 
   WHERE vl2.project_id = p.project_id 
   AND vl2.visited_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)) as seven_day_visits,
  (SELECT COUNT(*) FROM visit_logs vl3 
   WHERE vl3.project_id = p.project_id 
   AND vl3.visited_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)) as thirty_day_visits,
  CASE 
    WHEN p.expires_at IS NULL THEN 'permanent'
    WHEN p.expires_at < NOW() THEN 'expired'
    WHEN p.expires_at >= NOW() THEN 'active'
    ELSE 'unknown'
  END as expiry_status
FROM projects p
LEFT JOIN users u ON p.user_id = u.user_id
LEFT JOIN visit_logs vl ON p.project_id = vl.project_id
GROUP BY p.id;

-- =============================================
-- 视图：项目完整信息
-- =============================================
CREATE OR REPLACE VIEW `v_project_full` AS
SELECT 
  p.*,
  u.is_pro as user_is_pro,
  u.status as user_status,
  (SELECT COUNT(*) FROM visit_logs vl 
   WHERE vl.project_id = p.project_id 
   AND DATE(vl.visited_at) = CURDATE()) as today_visits,
  (SELECT COUNT(DISTINCT ip_address) FROM visit_logs vl 
   WHERE vl.project_id = p.project_id) as unique_visitors,
  (SELECT COUNT(*) FROM temp_access_links tal 
   WHERE tal.project_id = p.project_id 
   AND tal.expires_at > NOW()) as active_temp_links
FROM projects p
LEFT JOIN users u ON p.user_id = u.user_id
WHERE p.status != 'deleted';
