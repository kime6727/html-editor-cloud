-- ============================================================================
-- HTML Code Editor - v3.0 → v3.1 完整迁移脚本
-- ============================================================================
-- 用途: 将生产数据库从 init_mysql84.sql (v3.0) 升级到 init.sql (v3.1)
-- 执行: mysql -u root -p html_editor < migration_v3_final.sql
-- 注意: 执行前请备份数据库!
-- ============================================================================

USE `html_editor`;

-- ============================================================================
-- 第一步: 表结构变更 (ALTER TABLE)
-- ============================================================================

-- 1. users 表
-- 1a. 扩大 user_id 字段长度
ALTER TABLE `users` MODIFY `user_id` VARCHAR(64) NOT NULL COMMENT '用户唯一ID';

-- 1b. 添加 pro_expires_at 字段
ALTER TABLE `users` ADD COLUMN `pro_expires_at` DATETIME DEFAULT NULL COMMENT 'Pro过期时间' AFTER `pro_activated_at`;


-- 2. projects 表
-- 2a. 扩大 user_id 字段长度
ALTER TABLE `projects` MODIFY `user_id` VARCHAR(64) DEFAULT NULL COMMENT '发布者用户ID';

-- 2b. 添加 custom_slug 字段
ALTER TABLE `projects` ADD COLUMN `custom_slug` VARCHAR(50) DEFAULT NULL COMMENT '自定义短链别名' AFTER `expired_custom_message`;

-- 2c. 添加 idx_last_visited 索引
ALTER TABLE `projects` ADD INDEX `idx_last_visited` (`last_visited_at`);


-- 3. user_activity_logs 表
-- 3a. 扩大 user_id 字段长度
ALTER TABLE `user_activity_logs` MODIFY `user_id` VARCHAR(64) NOT NULL COMMENT '用户ID';

-- 3b. 将 action 从 ENUM 改为 VARCHAR(50)
ALTER TABLE `user_activity_logs` MODIFY `action` VARCHAR(50) NOT NULL COMMENT '操作类型: publish/update/delete/login/subscribe';

-- 3c. 添加 ip_address 字段
ALTER TABLE `user_activity_logs` ADD COLUMN `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '操作IP' AFTER `details`;

-- 3d. 替换索引: idx_user_action_created → idx_user_action
ALTER TABLE `user_activity_logs` DROP INDEX `idx_user_action_created`;
ALTER TABLE `user_activity_logs` ADD INDEX `idx_user_action` (`user_id`, `action`, `created_at`);


-- 4. admin_logs 表
-- 4a. 扩大 admin_user 字段长度
ALTER TABLE `admin_logs` MODIFY `admin_user` VARCHAR(64) NOT NULL COMMENT '管理员账号/用户ID';

-- 4b. 添加 idx_target_type 索引
ALTER TABLE `admin_logs` ADD INDEX `idx_target_type` (`target_type`);


-- 5. daily_stats 表
-- 5a. 添加 active_projects 字段
ALTER TABLE `daily_stats` ADD COLUMN `active_projects` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '活跃项目数' AFTER `total_projects`;


-- 6. subscription_records 表
-- 6a. 扩大 user_id 字段长度
ALTER TABLE `subscription_records` MODIFY `user_id` VARCHAR(64) NOT NULL COMMENT '用户ID';

-- 6b. 添加 original_transaction_id 字段
ALTER TABLE `subscription_records` ADD COLUMN `original_transaction_id` VARCHAR(100) DEFAULT NULL COMMENT '原始交易ID' AFTER `transaction_id`;

-- 6c. 添加 environment 字段
ALTER TABLE `subscription_records` ADD COLUMN `environment` VARCHAR(20) DEFAULT 'Production' COMMENT '沙盒/生产环境' AFTER `product_id`;

-- 6d. 扩展 status ENUM 添加 billing_retry
ALTER TABLE `subscription_records` MODIFY `status` ENUM('active','expired','refunded','cancelled','billing_retry') NOT NULL DEFAULT 'active' COMMENT '订阅状态';

-- 6e. 添加 cancellation_date 字段
ALTER TABLE `subscription_records` ADD COLUMN `cancellation_date` DATETIME DEFAULT NULL COMMENT '取消时间' AFTER `refund_date`;

-- 6f. 添加 created_at 字段
ALTER TABLE `subscription_records` ADD COLUMN `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER `cancellation_date`;

-- 6g. 添加 updated_at 字段
ALTER TABLE `subscription_records` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`;

-- 6h. 添加 idx_original_txn 索引
ALTER TABLE `subscription_records` ADD INDEX `idx_original_txn` (`original_transaction_id`);

-- 6i. 添加 idx_expires_at 索引
ALTER TABLE `subscription_records` ADD INDEX `idx_expires_at` (`expires_at`);


-- 7. temp_access_links 表
-- 7a. 添加 max_uses 字段
ALTER TABLE `temp_access_links` ADD COLUMN `max_uses` INT UNSIGNED DEFAULT 1 COMMENT '最大使用次数' AFTER `expires_at`;

-- 7b. 添加 created_by 字段
ALTER TABLE `temp_access_links` ADD COLUMN `created_by` VARCHAR(64) DEFAULT NULL COMMENT '创建者用户ID' AFTER `last_used_at`;


-- ============================================================================
-- 第二步: 更新系统配置
-- ============================================================================

-- 更新版本号
UPDATE `system_config` SET `config_value` = '3.1.0', `description` = '应用版本号' WHERE `config_key` = 'app_version';

-- 添加新增配置项 (INSERT IGNORE 保证幂等)
INSERT IGNORE INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
('max_single_file_size', '10485760', '单个文件最大字节数 (10MB)'),
('free_user_monthly_publish_limit', '1', '免费用户每月发布次数限制'),
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
-- 第三步: 更新视图 (CREATE OR REPLACE 保证幂等)
-- ============================================================================

-- 视图: 用户统计概览 (v3.1 更新: 添加 last_activity_at, 使用 COALESCE, 过滤 deleted)
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


-- 视图: 项目详细统计 (v3.1 重写: 使用子查询替代 GROUP BY, 添加 has_password)
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


-- 视图: 项目完整信息 (v3.1 重写: 使用子查询, COALESCE, ip_hash 去重)
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


-- 视图: 每日统计汇总 (新增)
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


-- 视图: 项目访问来源统计 (新增)
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
-- 第四步: 创建存储过程
-- ============================================================================

DELIMITER //

-- 存储过程: 清理过期访问日志 (新增)
DROP PROCEDURE IF EXISTS `sp_cleanup_visit_logs`//
CREATE PROCEDURE `sp_cleanup_visit_logs`(IN retention_days INT)
BEGIN
  DELETE FROM visit_logs
  WHERE visited_at < DATE_SUB(NOW(), INTERVAL retention_days DAY);
  SELECT ROW_COUNT() AS deleted_rows;
END //

-- 存储过程: 标记过期项目 (新增)
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

-- 存储过程: 聚合每日统计 (新增)
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
-- 第五步: 创建事件调度器
-- ============================================================================

-- 确保事件调度器开启
SET GLOBAL event_scheduler = ON;

-- 定时事件: 每5分钟标记过期项目 (新增)
DROP EVENT IF EXISTS `evt_expire_projects`;
CREATE EVENT `evt_expire_projects`
ON SCHEDULE EVERY 5 MINUTE
STARTS CURRENT_TIMESTAMP
DO CALL sp_expire_projects();

-- 定时事件: 每天凌晨聚合统计数据 (新增)
DROP EVENT IF EXISTS `evt_aggregate_stats`;
CREATE EVENT `evt_aggregate_stats`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO CALL sp_aggregate_daily_stats();


-- ============================================================================
-- 完成
-- ============================================================================
SELECT '============================================' AS '';
SELECT '  迁移完成! v3.0 → v3.1' AS '';
SELECT '============================================' AS '';
SELECT CONCAT('  配置项数: ', COUNT(*)) AS summary FROM system_config;
SELECT config_key, config_value FROM system_config
WHERE config_key IN (
  'app_version', 'free_user_expire_minutes',
  'enable_realtime_expiry_check', 'enable_password_protection', 'enable_visit_tracking'
);
