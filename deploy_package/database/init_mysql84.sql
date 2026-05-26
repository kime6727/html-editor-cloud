-- ============================================================================
-- HTML Code Editor - MySQL 8.4 完整初始化脚本
-- ============================================================================
-- 版本: v3.1
-- 日期: 2026-05-21
-- 适用: MySQL 8.4+
-- 特性: 使用MySQL 8.4新特性（UTF8MB4 0900排序规则、原子DDL、资源组等）
-- 用法: mysql -u root -p < init_mysql84.sql
-- ============================================================================

-- 创建数据库（使用MySQL 8.4推荐的排序规则）
CREATE DATABASE IF NOT EXISTS `html_editor`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE `html_editor`;

-- ============================================================================
-- 第一步: 数据表 (全部使用 IF NOT EXISTS 保证幂等)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. users - 用户表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL COMMENT '用户唯一ID',
  `is_pro` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否Pro用户 0=免费 1=Pro',
  `pro_activated_at` DATETIME DEFAULT NULL COMMENT 'Pro激活时间',
  `pro_expires_at` DATETIME DEFAULT NULL COMMENT 'Pro过期时间',
  `publish_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '累计发布次数',
  `total_visits` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总访问量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表';


-- ----------------------------------------------------------------------------
-- 2. projects - 项目表 (核心表)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `projects` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID (8-12位字母数字)',
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
  `expired_redirect_url` VARCHAR(500) DEFAULT NULL COMMENT '到期重定向URL',
  `expired_custom_message` TEXT DEFAULT NULL COMMENT '到期自定义消息',
  `custom_slug` VARCHAR(50) DEFAULT NULL COMMENT '自定义短链别名',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='项目表';


-- ----------------------------------------------------------------------------
-- 3. visit_logs - 访问日志表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `visit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID',
  `ip_address` VARCHAR(45) NOT NULL COMMENT '访问IP (已匿名脱敏)',
  `ip_hash` VARCHAR(16) DEFAULT NULL COMMENT 'IP哈希 (用于去重统计)',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '浏览器User-Agent',
  `referer` VARCHAR(500) DEFAULT NULL COMMENT '来源页面Referer',
  `country` VARCHAR(50) DEFAULT NULL COMMENT '国家 (可选)',
  `city` VARCHAR(50) DEFAULT NULL COMMENT '城市 (可选)',
  `device_type` ENUM('mobile','tablet','desktop','unknown') DEFAULT 'unknown' COMMENT '设备类型',
  `visited_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '访问时间',
  PRIMARY KEY (`id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_visited_at` (`visited_at`),
  KEY `idx_device_type` (`device_type`),
  KEY `idx_project_visited` (`project_id`,`visited_at`),
  KEY `idx_project_device` (`project_id`,`device_type`),
  KEY `idx_project_referer` (`project_id`,`referer`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='访问日志表';


-- ----------------------------------------------------------------------------
-- 4. user_activity_logs - 用户活动日志表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_activity_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL COMMENT '用户ID',
  `project_id` VARCHAR(20) DEFAULT NULL COMMENT '关联项目ID',
  `action` VARCHAR(50) NOT NULL COMMENT '操作类型: publish/update/delete/login/subscribe',
  `details` JSON DEFAULT NULL COMMENT '操作详情JSON',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '操作IP',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_user_action` (`user_id`,`action`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户活动日志表';


-- ----------------------------------------------------------------------------
-- 5. admin_logs - 管理员操作日志表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_user` VARCHAR(64) NOT NULL COMMENT '管理员账号/用户ID',
  `action` VARCHAR(50) NOT NULL COMMENT '操作类型',
  `target_type` ENUM('user','project','system') NOT NULL COMMENT '操作目标类型',
  `target_id` VARCHAR(100) DEFAULT NULL COMMENT '操作目标ID',
  `details` JSON DEFAULT NULL COMMENT '操作详情JSON',
  `ip_address` VARCHAR(45) NOT NULL COMMENT '操作IP',
  `ip_hash` VARCHAR(16) DEFAULT NULL COMMENT 'IP哈希',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_admin_user` (`admin_user`),
  KEY `idx_action` (`action`),
  KEY `idx_target_type` (`target_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='管理员操作日志表';


-- ----------------------------------------------------------------------------
-- 6. daily_stats - 每日统计缓存表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `daily_stats` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `stat_date` DATE NOT NULL COMMENT '统计日期',
  `total_projects` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总项目数',
  `active_projects` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '活跃项目数',
  `total_visits` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总访问量',
  `new_users` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '新用户数',
  `active_users` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '活跃用户数',
  `pro_users` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Pro用户数',
  `publish_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '发布次数',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stat_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='每日统计缓存表';


-- ----------------------------------------------------------------------------
-- 7. system_config - 系统配置表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `system_config` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_key` VARCHAR(100) NOT NULL COMMENT '配置键',
  `config_value` TEXT DEFAULT NULL COMMENT '配置值',
  `description` VARCHAR(255) DEFAULT NULL COMMENT '配置说明',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统配置表';


-- ----------------------------------------------------------------------------
-- 8. subscription_records - 订阅记录表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `subscription_records` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(64) NOT NULL COMMENT '用户ID',
  `transaction_id` VARCHAR(100) DEFAULT NULL COMMENT 'Apple交易ID',
  `original_transaction_id` VARCHAR(100) DEFAULT NULL COMMENT '原始交易ID',
  `product_id` VARCHAR(100) NOT NULL COMMENT '产品ID',
  `environment` VARCHAR(20) DEFAULT 'Production' COMMENT '沙盒/生产环境',
  `status` ENUM('active','expired','refunded','cancelled','billing_retry') NOT NULL DEFAULT 'active' COMMENT '订阅状态',
  `purchased_at` DATETIME NOT NULL COMMENT '购买时间',
  `expires_at` DATETIME DEFAULT NULL COMMENT '过期时间',
  `refund_date` DATETIME DEFAULT NULL COMMENT '退款时间',
  `cancellation_date` DATETIME DEFAULT NULL COMMENT '取消时间',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_transaction_id` (`transaction_id`),
  KEY `idx_original_txn` (`original_transaction_id`),
  KEY `idx_status` (`status`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='订阅记录表';


-- ----------------------------------------------------------------------------
-- 9. temp_access_links - 临时访问链接表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `temp_access_links` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` VARCHAR(20) NOT NULL COMMENT '项目短ID',
  `token` VARCHAR(64) NOT NULL COMMENT '临时访问令牌 (32字节hex)',
  `expires_at` DATETIME NOT NULL COMMENT '令牌过期时间',
  `max_uses` INT UNSIGNED DEFAULT 1 COMMENT '最大使用次数',
  `used_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '已使用次数',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `last_used_at` DATETIME DEFAULT NULL COMMENT '最后使用时间',
  `created_by` VARCHAR(64) DEFAULT NULL COMMENT '创建者用户ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_token` (`token`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='临时访问链接表';


-- ============================================================================
-- 第二步: 插入默认系统配置 (使用 INSERT IGNORE 保证幂等)
-- ============================================================================
INSERT IGNORE INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('app_version', '3.1.0', '应用版本号'),
('maintenance_mode', '0', '维护模式: 0=关闭 1=开启'),
('max_upload_size', '10485760', '单次上传最大字节数 (10MB)'),
('max_single_file_size', '10485760', '单个文件最大字节数 (10MB)'),
('free_user_expire_minutes', '60', '免费用户过期分钟数 (1小时)'),
('free_user_monthly_publish_limit', '1', '免费用户每月发布次数限制'),
('default_domain', 'https://html.weburl.cloudns.be', '默认站点域名'),
('enable_realtime_expiry_check', '1', '启用实时过期检查 (index.php网关)'),
('enable_password_protection', '1', '启用访问密码保护功能'),
('enable_visit_tracking', '1', '启用访问日志记录'),
('session_timeout_minutes', '60', '密码验证Session有效期 (分钟)'),
('expired_redirect_enabled', '1', '启用到期重定向功能'),
('rate_limit_requests', '30', '速率限制: 每分钟最大请求数'),
('hmac_timestamp_window', '300', 'HMAC时间戳窗口 (秒)'),
('visit_log_retention_days', '90', '访问日志保留天数'),
('deleted_project_retention_days', '30', '已删除项目保留天数');

-- 幂等更新: 确保关键配置为最新值
INSERT INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('free_user_expire_minutes', '60', '免费用户过期分钟数 (1小时)'),
('enable_realtime_expiry_check', '1', '启用实时过期检查 (index.php网关)'),
('enable_password_protection', '1', '启用访问密码保护功能'),
('enable_visit_tracking', '1', '启用访问日志记录'),
('session_timeout_minutes', '60', '密码验证Session有效期 (分钟)')
ON DUPLICATE KEY UPDATE
  `config_value` = VALUES(`config_value`),
  `description` = VALUES(`description`);


-- ============================================================================
-- 第三步: 创建视图 (使用 CREATE OR REPLACE 保证幂等)
-- ============================================================================

-- 视图: 用户统计概览
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
  COUNT(DISTINCT p.id) AS project_count,
  COALESCE(SUM(p.visit_count), 0) AS total_project_visits,
  MAX(p.created_at) AS last_publish_at,
  MAX(p.updated_at) AS last_activity_at
FROM users u
LEFT JOIN projects p ON u.user_id = p.user_id AND p.status NOT IN ('deleted')
GROUP BY u.id;


-- 视图: 项目详细统计 (含过期状态、设备统计)
CREATE OR REPLACE VIEW `v_project_stats` AS
SELECT
  p.id,
  p.project_id,
  p.project_name,
  p.user_id,
  p.is_pro,
  p.file_count,
  p.visit_count,
  p.status,
  p.expires_at,
  p.access_password,
  p.created_at,
  p.updated_at,
  p.last_visited_at,
  u.is_pro AS user_is_pro,
  u.status AS user_status,
  COALESCE(t.today_visits, 0) AS today_visits,
  COALESCE(s.seven_day_visits, 0) AS seven_day_visits,
  COALESCE(m.thirty_day_visits, 0) AS thirty_day_visits,
  CASE
    WHEN p.expires_at IS NULL THEN 'permanent'
    WHEN p.expires_at < NOW() THEN 'expired'
    WHEN p.status = 'inactive' THEN 'inactive'
    ELSE 'active'
  END AS expiry_status,
  CASE
    WHEN p.access_password IS NOT NULL AND p.access_password != '' THEN 1
    ELSE 0
  END AS has_password
FROM projects p
LEFT JOIN users u ON p.user_id = u.user_id
LEFT JOIN (
  SELECT project_id, COUNT(*) AS today_visits
  FROM visit_logs WHERE DATE(visited_at) = CURDATE()
  GROUP BY project_id
) t ON t.project_id = p.project_id
LEFT JOIN (
  SELECT project_id, COUNT(*) AS seven_day_visits
  FROM visit_logs WHERE visited_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
  GROUP BY project_id
) s ON s.project_id = p.project_id
LEFT JOIN (
  SELECT project_id, COUNT(*) AS thirty_day_visits
  FROM visit_logs WHERE visited_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
  GROUP BY project_id
) m ON m.project_id = p.project_id
WHERE p.status != 'deleted';


-- 视图: 项目完整信息 (用于管理后台)
CREATE OR REPLACE VIEW `v_project_full` AS
SELECT
  p.*,
  u.is_pro AS user_is_pro,
  u.status AS user_status,
  COALESCE(t.today_visits, 0) AS today_visits,
  COALESCE(uv.unique_visitors, 0) AS unique_visitors,
  COALESCE(tl.active_temp_links, 0) AS active_temp_links
FROM projects p
LEFT JOIN users u ON p.user_id = u.user_id
LEFT JOIN (
  SELECT project_id, COUNT(*) AS today_visits
  FROM visit_logs WHERE DATE(visited_at) = CURDATE()
  GROUP BY project_id
) t ON t.project_id = p.project_id
LEFT JOIN (
  SELECT project_id, COUNT(DISTINCT ip_hash) AS unique_visitors
  FROM visit_logs
  GROUP BY project_id
) uv ON uv.project_id = p.project_id
LEFT JOIN (
  SELECT project_id, COUNT(*) AS active_temp_links
  FROM temp_access_links WHERE expires_at > NOW()
  GROUP BY project_id
) tl ON tl.project_id = p.project_id
WHERE p.status != 'deleted';


-- 视图: 每日统计汇总
CREATE OR REPLACE VIEW `v_daily_summary` AS
SELECT
  DATE(vl.visited_at) AS visit_date,
  COUNT(*) AS total_visits,
  COUNT(DISTINCT vl.project_id) AS active_projects,
  COUNT(DISTINCT vl.ip_hash) AS unique_visitors,
  SUM(CASE WHEN vl.device_type = 'mobile' THEN 1 ELSE 0 END) AS mobile_visits,
  SUM(CASE WHEN vl.device_type = 'tablet' THEN 1 ELSE 0 END) AS tablet_visits,
  SUM(CASE WHEN vl.device_type = 'desktop' THEN 1 ELSE 0 END) AS desktop_visits
FROM visit_logs vl
GROUP BY DATE(vl.visited_at)
ORDER BY visit_date DESC;


-- 视图: 项目访问来源统计
CREATE OR REPLACE VIEW `v_referrer_stats` AS
SELECT
  vl.project_id,
  p.project_name,
  vl.referer,
  COUNT(*) AS visit_count,
  MAX(vl.visited_at) AS last_visit
FROM visit_logs vl
JOIN projects p ON vl.project_id = p.project_id
WHERE vl.referer IS NOT NULL AND vl.referer != ''
GROUP BY vl.project_id, vl.referer
ORDER BY visit_count DESC;


-- ============================================================================
-- 第四步: 创建存储过程 (定时任务辅助)
-- ============================================================================

DELIMITER //

-- 存储过程: 清理过期访问日志
DROP PROCEDURE IF EXISTS `sp_cleanup_visit_logs`//
CREATE PROCEDURE `sp_cleanup_visit_logs`(IN retention_days INT)
BEGIN
  DELETE FROM visit_logs
  WHERE visited_at < DATE_SUB(NOW(), INTERVAL retention_days DAY);
  SELECT ROW_COUNT() AS deleted_rows;
END //

-- 存储过程: 标记过期项目
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

-- 存储过程: 聚合每日统计
DROP PROCEDURE IF EXISTS `sp_aggregate_daily_stats`//
CREATE PROCEDURE `sp_aggregate_daily_stats`()
BEGIN
  INSERT INTO daily_stats
    (stat_date, total_projects, active_projects, total_visits, new_users, active_users, pro_users, publish_count)
  SELECT
    CURDATE() - INTERVAL 1 DAY,
    (SELECT COUNT(*) FROM projects),
    (SELECT COUNT(*) FROM projects WHERE status = 'active'),
    (SELECT COUNT(*) FROM visit_logs WHERE DATE(visited_at) = CURDATE() - INTERVAL 1 DAY),
    (SELECT COUNT(*) FROM users WHERE DATE(created_at) = CURDATE() - INTERVAL 1 DAY),
    (SELECT COUNT(*) FROM users WHERE DATE(last_active_at) = CURDATE() - INTERVAL 1 DAY),
    (SELECT COUNT(*) FROM users WHERE is_pro = 1 AND status = 'active'),
    (SELECT COUNT(*) FROM user_activity_logs WHERE action = 'publish' AND DATE(created_at) = CURDATE() - INTERVAL 1 DAY)
  ON DUPLICATE KEY UPDATE
    total_projects = VALUES(total_projects),
    active_projects = VALUES(active_projects),
    total_visits = VALUES(total_visits),
    new_users = VALUES(new_users),
    active_users = VALUES(active_users),
    pro_users = VALUES(pro_users),
    publish_count = VALUES(publish_count);
END //

DELIMITER ;


-- ============================================================================
-- 第五步: 创建事件调度器 (MySQL 8.4 原子DDL)
-- ============================================================================

-- 确保事件调度器开启
SET GLOBAL event_scheduler = ON;

-- 定时事件: 每5分钟标记过期项目
DROP EVENT IF EXISTS `evt_expire_projects`;
CREATE EVENT `evt_expire_projects`
ON SCHEDULE EVERY 5 MINUTE
STARTS CURRENT_TIMESTAMP
DO CALL sp_expire_projects();

-- 定时事件: 每天凌晨聚合统计数据
DROP EVENT IF EXISTS `evt_aggregate_stats`;
CREATE EVENT `evt_aggregate_stats`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO CALL sp_aggregate_daily_stats();


-- ============================================================================
-- 完成
-- ============================================================================
SELECT '========================================' AS '';
SELECT '  数据库初始化完成! (html_editor v3.1)' AS '';
SELECT '  MySQL 8.4+ (utf8mb4_0900_ai_ci)' AS '';
SELECT '========================================' AS '';
SELECT CONCAT('  表数量: ', COUNT(*)) AS summary FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'html_editor' AND TABLE_TYPE = 'BASE TABLE';
SELECT CONCAT('  视图数量: ', COUNT(*)) AS summary FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'html_editor';
SELECT CONCAT('  配置项数: ', COUNT(*)) AS summary FROM system_config;

-- 显示关键配置
SELECT config_key, config_value FROM system_config
WHERE config_key IN (
  'app_version', 'free_user_expire_minutes',
  'enable_realtime_expiry_check', 'enable_password_protection', 'enable_visit_tracking'
);
