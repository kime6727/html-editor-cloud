-- ============================================================================
-- HTML Code Editor - 外部数据库初始化脚本
-- 适用: 任何 MySQL 5.7+ / MariaDB 10.3+ 平台
-- 用法: 先创建空库 html_editor，然后 mysql -h HOST -u USER -p html_editor < init_external.sql
-- ============================================================================

-- ============================================================================
-- 数据表
-- ============================================================================

CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL,
  `is_pro` TINYINT(1) NOT NULL DEFAULT 0,
  `pro_activated_at` DATETIME DEFAULT NULL,
  `pro_expires_at` DATETIME DEFAULT NULL,
  `publish_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_visits` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_active_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` ENUM('active','banned','suspended') NOT NULL DEFAULT 'active',
  `ban_reason` VARCHAR(255) DEFAULT NULL,
  `banned_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `idx_is_pro` (`is_pro`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_last_active` (`last_active_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `projects` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL,
  `project_name` VARCHAR(255) NOT NULL DEFAULT 'Untitled',
  `user_id` VARCHAR(64) DEFAULT NULL,
  `is_pro` TINYINT(1) NOT NULL DEFAULT 0,
  `file_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `visit_count` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `status` ENUM('active','inactive','expired','deleted','banned') NOT NULL DEFAULT 'active',
  `expire_days` INT UNSIGNED NOT NULL DEFAULT 0,
  `expire_minutes` INT UNSIGNED NOT NULL DEFAULT 0,
  `expires_at` DATETIME DEFAULT NULL,
  `access_password` VARCHAR(255) DEFAULT NULL,
  `expired_redirect_type` ENUM('app_promotion','custom_url','custom_message') NOT NULL DEFAULT 'app_promotion',
  `expired_redirect_url` VARCHAR(500) DEFAULT NULL,
  `expired_custom_message` TEXT DEFAULT NULL,
  `custom_slug` VARCHAR(50) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_visited_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_id` (`project_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_visit_count` (`visit_count`),
  KEY `idx_last_visited` (`last_visited_at`),
  KEY `idx_user_status_created` (`user_id`,`status`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `visit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL,
  `ip_address` VARCHAR(45) NOT NULL,
  `ip_hash` VARCHAR(16) DEFAULT NULL,
  `user_agent` VARCHAR(500) DEFAULT NULL,
  `referer` VARCHAR(500) DEFAULT NULL,
  `country` VARCHAR(50) DEFAULT NULL,
  `city` VARCHAR(50) DEFAULT NULL,
  `device_type` ENUM('mobile','tablet','desktop','unknown') DEFAULT 'unknown',
  `visited_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_visited_at` (`visited_at`),
  KEY `idx_device_type` (`device_type`),
  KEY `idx_project_visited` (`project_id`,`visited_at`),
  KEY `idx_project_device` (`project_id`,`device_type`),
  KEY `idx_project_referer` (`project_id`,`referer`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_activity_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL,
  `project_id` VARCHAR(20) DEFAULT NULL,
  `action` VARCHAR(50) NOT NULL,
  `details` JSON DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_user_action` (`user_id`,`action`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_user` VARCHAR(64) NOT NULL,
  `action` VARCHAR(50) NOT NULL,
  `target_type` ENUM('user','project','system') NOT NULL,
  `target_id` VARCHAR(100) DEFAULT NULL,
  `details` JSON DEFAULT NULL,
  `ip_address` VARCHAR(45) NOT NULL,
  `ip_hash` VARCHAR(16) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin_user` (`admin_user`),
  KEY `idx_action` (`action`),
  KEY `idx_target_type` (`target_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `daily_stats` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `stat_date` DATE NOT NULL,
  `total_projects` INT UNSIGNED NOT NULL DEFAULT 0,
  `active_projects` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_visits` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `new_users` INT UNSIGNED NOT NULL DEFAULT 0,
  `active_users` INT UNSIGNED NOT NULL DEFAULT 0,
  `pro_users` INT UNSIGNED NOT NULL DEFAULT 0,
  `publish_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stat_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `system_config` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_key` VARCHAR(100) NOT NULL,
  `config_value` TEXT DEFAULT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `subscription_records` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL,
  `transaction_id` VARCHAR(100) DEFAULT NULL,
  `original_transaction_id` VARCHAR(100) DEFAULT NULL,
  `product_id` VARCHAR(100) NOT NULL,
  `environment` VARCHAR(20) DEFAULT 'Production',
  `status` ENUM('active','expired','refunded','cancelled','billing_retry') NOT NULL DEFAULT 'active',
  `purchased_at` DATETIME NOT NULL,
  `expires_at` DATETIME DEFAULT NULL,
  `refund_date` DATETIME DEFAULT NULL,
  `cancellation_date` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_transaction_id` (`transaction_id`),
  KEY `idx_original_txn` (`original_transaction_id`),
  KEY `idx_status` (`status`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `temp_access_links` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL,
  `token` VARCHAR(64) NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `max_uses` INT UNSIGNED DEFAULT 1,
  `used_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_used_at` DATETIME DEFAULT NULL,
  `created_by` VARCHAR(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_token` (`token`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 默认系统配置
-- ============================================================================
INSERT IGNORE INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('app_version', '3.2.0', '应用版本号'),
('max_upload_size', '10485760', '单次上传最大字节数 (10MB)'),
('free_user_expire_minutes', '60', '免费用户过期分钟数'),
('free_user_monthly_publish_limit', '1', '免费用户每月发布次数限制'),
('enable_realtime_expiry_check', '1', '启用实时过期检查'),
('enable_password_protection', '1', '启用访问密码保护'),
('enable_visit_tracking', '1', '启用访问日志记录'),
('session_timeout_minutes', '60', '密码验证Session有效期'),
('rate_limit_requests', '30', '速率限制: 每分钟最大请求数'),
('hmac_timestamp_window', '300', 'HMAC时间戳窗口'),
('visit_log_retention_days', '90', '访问日志保留天数');

-- ============================================================================
-- 完成
-- ============================================================================
SELECT 'OK - 9 tables + config created' AS status;