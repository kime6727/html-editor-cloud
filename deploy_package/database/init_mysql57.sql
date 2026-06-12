-- ============================================================================
-- HTML Code Editor - MySQL 5.7 完整初始化脚本
-- ============================================================================
-- 版本: v3.2
-- 日期: 2026-06-02
-- 适用: MySQL 5.7.44
-- 兼容: 同时支持 MySQL 5.7 / MariaDB 10.3+
--
-- v3.2 变更:
--   - 移除: daily_stats, subscription_records, temp_access_links, project_ip_rules,
--           project_comments, tags, categories, project_tags
--   - 移除: v_user_stats, v_project_stats, v_project_full, v_daily_summary,
--           v_referrer_stats 视图
--   - 移除: sp_aggregate_daily_stats, sp_cleanup_visit_logs, evt_aggregate_stats
--   - 移除: visit_logs.country/city/device_type/browser/os 字段
--   - 移除: projects.thumbnail/thumbnail_url/temp_link_* 字段
--   - 修正: free_user_monthly_publish_limit 统一为 3
--   - 清理: system_config 仅保留业务实际使用的项
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `html_editor`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `html_editor`;


-- 1. users - 用户表
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL COMMENT '用户唯一ID',
  `is_pro` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否Pro用户 0=免费 1=Pro',
  `pro_activated_at` DATETIME DEFAULT NULL COMMENT 'Pro激活时间',
  `pro_expires_at` DATETIME DEFAULT NULL COMMENT 'Pro过期时间',
  `publish_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '累计发布次数',
  `total_visits` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总访问量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `last_active_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后活跃时间',
  `status` ENUM('active','banned','suspended') NOT NULL DEFAULT 'active' COMMENT '用户状态',
  `ban_reason` VARCHAR(255) DEFAULT NULL COMMENT '封禁原因',
  `banned_at` DATETIME DEFAULT NULL COMMENT '封禁时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `idx_is_pro` (`is_pro`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_last_active` (`last_active_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';


-- 2. projects - 项目表
CREATE TABLE IF NOT EXISTS `projects` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID',
  `project_name` VARCHAR(255) NOT NULL DEFAULT 'Untitled' COMMENT '项目名称',
  `user_id` VARCHAR(64) DEFAULT NULL COMMENT '发布者用户ID',
  `is_pro` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '发布时用户是否为Pro',
  `file_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '文件数量',
  `visit_count` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总访问次数',
  `status` ENUM('active','inactive','expired','deleted','banned') NOT NULL DEFAULT 'active' COMMENT '项目状态',
  `expire_days` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '过期天数 (0=按分钟计)',
  `expire_minutes` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '过期分钟数',
  `expires_at` DATETIME DEFAULT NULL COMMENT '过期时间 NULL=永久',
  `access_password` VARCHAR(255) DEFAULT NULL COMMENT '访问密码 (bcrypt哈希)',
  `expired_redirect_type` ENUM('app_promotion','custom_url','custom_message') NOT NULL DEFAULT 'app_promotion' COMMENT '到期后动作类型',
  `expired_redirect_url` VARCHAR(500) DEFAULT NULL COMMENT '到期重定向URL (仅同源白名单)',
  `expired_custom_message` TEXT DEFAULT NULL COMMENT '到期自定义消息',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `last_visited_at` DATETIME DEFAULT NULL COMMENT '最后访问时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_id` (`project_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_visit_count` (`visit_count`),
  KEY `idx_last_visited` (`last_visited_at`),
  KEY `idx_user_status_created` (`user_id`,`status`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目表';


-- 3. visit_logs - 访问日志表
CREATE TABLE IF NOT EXISTS `visit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID',
  `ip_address` VARCHAR(45) NOT NULL COMMENT '访问IP (已匿名脱敏)',
  `ip_hash` VARCHAR(16) DEFAULT NULL COMMENT 'IP哈希 (用于去重统计)',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '浏览器User-Agent',
  `referer` VARCHAR(500) DEFAULT NULL COMMENT '来源页面Referer',
  `visited_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '访问时间',
  PRIMARY KEY (`id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_visited_at` (`visited_at`),
  KEY `idx_ip_hash` (`ip_hash`),
  KEY `idx_project_visited` (`project_id`,`visited_at`),
  KEY `idx_project_referer` (`project_id`,`referer`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='访问日志表';


-- 4. user_activity_logs - 用户活动日志表
CREATE TABLE IF NOT EXISTS `user_activity_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL COMMENT '用户ID',
  `project_id` VARCHAR(20) DEFAULT NULL COMMENT '关联项目ID',
  `action` VARCHAR(50) NOT NULL COMMENT '操作类型',
  `details` JSON DEFAULT NULL COMMENT '详细信息',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '操作IP',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_user_action` (`user_id`,`action`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户活动日志表';


-- 5. admin_logs - 管理员操作日志表
CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_user` VARCHAR(64) NOT NULL COMMENT '管理员账号',
  `action` VARCHAR(50) NOT NULL COMMENT '操作类型',
  `target_type` ENUM('user','project','system') NOT NULL COMMENT '目标类型',
  `target_id` VARCHAR(100) DEFAULT NULL COMMENT '目标ID',
  `details` JSON DEFAULT NULL COMMENT '详细信息',
  `ip_address` VARCHAR(45) NOT NULL COMMENT '管理员IP (已匿名脱敏)',
  `ip_hash` VARCHAR(16) DEFAULT NULL COMMENT 'IP哈希',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_admin_user` (`admin_user`),
  KEY `idx_action` (`action`),
  KEY `idx_target_type` (`target_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员操作日志表';


-- 6. system_config - 系统配置表
CREATE TABLE IF NOT EXISTS `system_config` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_key` VARCHAR(100) NOT NULL,
  `config_value` TEXT DEFAULT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';


-- 插入默认系统配置（仅保留业务实际使用的项）
INSERT IGNORE INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('free_user_expire_minutes', '60', '免费用户过期分钟数 (1小时)'),
('free_user_monthly_publish_limit', '3', '免费用户每月发布次数限制');

-- 幂等更新: 确保关键配置为最新值
INSERT INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('free_user_expire_minutes', '60', '免费用户过期分钟数 (1小时)'),
('free_user_monthly_publish_limit', '3', '免费用户每月发布次数限制')
ON DUPLICATE KEY UPDATE
  `config_value` = VALUES(`config_value`),
  `description` = VALUES(`description`);


-- 存储过程: 标记过期项目
DELIMITER //
DROP PROCEDURE IF EXISTS `sp_expire_projects`//
CREATE PROCEDURE `sp_expire_projects`()
BEGIN
  UPDATE projects
  SET status = 'expired', updated_at = NOW()
  WHERE status = 'active'
    AND expires_at IS NOT NULL
    AND expires_at < NOW();
  SELECT ROW_COUNT() AS expired_projects;
END //
DELIMITER ;


-- 启用事件调度器
SET GLOBAL event_scheduler = ON;

-- 定时事件: 每5分钟标记过期项目
DROP EVENT IF EXISTS `evt_expire_projects`;
CREATE EVENT `evt_expire_projects`
ON SCHEDULE EVERY 5 MINUTE
STARTS CURRENT_TIMESTAMP
DO CALL sp_expire_projects();


-- 完成提示
SELECT '========================================' AS '';
SELECT '  MySQL 5.7 数据库初始化完成! (v3.2)' AS '';
SELECT '========================================' AS '';
SELECT config_key, config_value FROM system_config
WHERE config_key IN (
  'free_user_expire_minutes', 'free_user_monthly_publish_limit'
);
