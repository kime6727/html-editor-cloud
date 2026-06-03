-- ============================================================================
-- 数据库清理 Migration v3.2
-- 日期: 2026-06-02
-- 用途: 移除所有"未实现"或"占位"的表/视图/字段/过程/事件
--      目标: 清理后只保留核心业务表 + 真实使用中的 system_config 项
--
-- 可安全重复执行（IF EXISTS 全部加上）
-- 适用: MySQL 5.7+ / MariaDB 10.3+
-- ============================================================================

USE `html_editor`;

-- ============================================================================
-- 第一步: 删除视图（无依赖，可直接 DROP）
-- ============================================================================
DROP VIEW IF EXISTS `v_user_stats`;
DROP VIEW IF EXISTS `v_project_stats`;
DROP VIEW IF EXISTS `v_project_full`;
DROP VIEW IF EXISTS `v_daily_summary`;
DROP VIEW IF EXISTS `v_referrer_stats`;


-- ============================================================================
-- 第二步: 删除未实现功能对应的表
-- ============================================================================
-- 临时访问链接
DROP TABLE IF EXISTS `temp_access_links`;

-- IP 黑/白名单
DROP TABLE IF EXISTS `project_ip_rules`;

-- 项目评论
DROP TABLE IF EXISTS `project_comments`;

-- 项目标签 / 分类
DROP TABLE IF EXISTS `project_tags`;
DROP TABLE IF EXISTS `tags`;
DROP TABLE IF EXISTS `categories`;

-- 每日统计缓存（事件/存储过程未启用 → 数据从未产生）
DROP TABLE IF EXISTS `daily_stats`;


-- ============================================================================
-- 第三步: 删除未使用的存储过程 / 事件
-- ============================================================================
DROP EVENT IF EXISTS `evt_aggregate_stats`;
DROP PROCEDURE IF EXISTS `sp_aggregate_daily_stats`;
DROP PROCEDURE IF EXISTS `sp_cleanup_visit_logs`;


-- ============================================================================
-- 第四步: 删除 projects 表上未实现的字段
-- ============================================================================
-- 临时链接相关（v3.1 未交付）
ALTER TABLE `projects` DROP COLUMN IF EXISTS `temp_link_enabled`;
ALTER TABLE `projects` DROP COLUMN IF EXISTS `temp_link_expires_at`;
ALTER TABLE `projects` DROP COLUMN IF EXISTS `temp_link_token`;

-- 分享 IM 缩略图（未实现）
ALTER TABLE `projects` DROP COLUMN IF EXISTS `thumbnail`;
ALTER TABLE `projects` DROP COLUMN IF EXISTS `thumbnail_url`;


-- ============================================================================
-- 第五步: 删除 visit_logs 表上未实现的字段
-- ============================================================================
-- 国家 / 城市（topCountries API 已移除，字段永远 NULL）
ALTER TABLE `visit_logs` DROP COLUMN IF EXISTS `country`;
ALTER TABLE `visit_logs` DROP COLUMN IF EXISTS `city`;

-- 设备类型 / 浏览器（未在任何业务流使用）
ALTER TABLE `visit_logs` DROP COLUMN IF EXISTS `device_type`;
ALTER TABLE `visit_logs` DROP COLUMN IF EXISTS `browser`;
ALTER TABLE `visit_logs` DROP COLUMN IF EXISTS `os`;


-- ============================================================================
-- 第六步: 删除 projects.thumbnails 上的冗余索引
-- ============================================================================
-- 无（按需补充）


-- ============================================================================
-- 第七步: 清理 system_config 中未使用的项
-- ============================================================================
-- 保留核心项：free_user_monthly_publish_limit / free_user_expire_minutes
-- 其它项要么从未读取、要么暂时不需要
DELETE FROM `system_config` WHERE `config_key` IN (
  'temp_link_max_duration_hours',
  'session_timeout_minutes',
  'rate_limit_requests',
  'hmac_timestamp_window',
  'visit_log_retention_days',
  'deleted_project_retention_days',
  'expired_redirect_enabled',
  'enable_realtime_expiry_check',
  'enable_password_protection',
  'enable_visit_tracking',
  'default_domain',
  'maintenance_mode',
  'max_upload_size',
  'max_single_file_size',
  'app_version'
);

-- 修正 free_user_monthly_publish_limit 为 3（与 iOS / PHP 默认值一致）
INSERT INTO `system_config` (`config_key`, `config_value`, `description`) VALUES
  ('free_user_monthly_publish_limit', '3', '免费用户每月发布次数限制')
ON DUPLICATE KEY UPDATE
  `config_value` = VALUES(`config_value`),
  `description` = VALUES(`description`);


-- ============================================================================
-- 第八步: 删除 subscription_records（iOS 端从未写入）
-- ============================================================================
DROP TABLE IF EXISTS `subscription_records`;


-- ============================================================================
-- 完成
-- ============================================================================
SELECT 'Cleanup v3.2 completed' AS status;
