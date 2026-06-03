# 更新日志

所有重要的项目变更都会记录在这个文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

> **产品**：Code Editor – HTML & Preview  
> **Bundle ID**：`com.niceapp.htmleditor` · **Apple ID**：`6764022927`  
> **App Store**：https://apps.apple.com/CN/app/id6764022927  
> **后端**：https://html.niceapp.eu.cc （Dokploy 部署）

## [3.2.1] - 2026-06-03

### 文档 📚
- **删除**：`CLOUD_PUBLISH_ANALYSIS.md`（v3.2 已修复全部 P0/P1 问题，报告已无参考价值）
- **同步**：免费用户发布次数统一描述为「3 次 / 月」（DB / PHP / iOS 三端一致）
- **同步**：免费用户过期时长描述为「1 小时（60 分钟）」强制（来自 `publish.php` 默认逻辑）
- **同步**：移除所有"自定义短链 / 短链接生成 / 短链后缀"描述（API 未实现 `custom_slug` 路由，项目访问地址固定为 `https://html.niceapp.eu.cc/pub/{project_id}/index.html`）
- **同步**：移除"5 个项目"免费限制描述（未实现）
- **修正**：`API.md` 端点 `detail` → `get`、`logs` → `get_visit_logs`，并补齐 `toggle_status / update_content / set_redirect_url / batch_operation` 4 个 action

## [3.2.0] - 2026-06-02

### 清理 🧹

#### 数据库清理
- **移除表**：`daily_stats`、`subscription_records`、`temp_access_links`、`project_ip_rules`、`project_comments`、`tags`、`categories`、`project_tags`
- **移除视图**：`v_user_stats`、`v_project_stats`、`v_project_full`、`v_daily_summary`、`v_referrer_stats`
- **移除存储过程**：`sp_aggregate_daily_stats`、`sp_cleanup_visit_logs`
- **移除事件**：`evt_aggregate_stats`
- **移除字段**：`visit_logs.country / city / device_type / browser / os`、`projects.thumbnail / thumbnail_url / temp_link_*`
- **统一配置**：`free_user_monthly_publish_limit` 统一为 `3`（之前 DB=1, PHP=3, iOS=3）

#### API 清理
- **移除端点**：`action=create_temp_link`（已 410 → 已删除）
- **移除字段**：`stats.topCountries`（从未实现，UI 永远空数组）
- **修复**：`handleGetVisitLogs` 移除 `device_type` 字段依赖，从 User-Agent 推断
- **修复**：`recordVisit()` 移除 `device_type` 字段依赖
- **新增**：`getConfig()` 工具函数，从 `system_config` 读配置

#### iOS 清理
- **移除模型**：`VisitStatistics`、`CountryStat`、`TopCountry`（死代码，从未被调用）
- **移除函数**：`getVisitStatistics()`（死代码）
- **移除状态**：`showStatsDetail`（死状态，按钮点击无任何响应）
- **移除 UI**：「查看详情」按钮（点击无任何响应）
- **移除本地化**：`view_details`、`temp_link_*` 共 22 条（中英双语）
- **替换测试**：「Verify Password API Test」→「Set Password API Test」（测试新端点而非已废弃端点）
- **新增**：`AppConfig.officialWebsiteURL` 官方 app 官网

#### 文档清理
- **移除描述**：临时访问链接、文件历史版本、协作编辑、CDN 加速、自定义域名、评论/留言、付费下载、IM 缩略图、IP 黑/白名单、项目搜索/标签、国家统计、自定义短链

## [2.0.0] - 2026-05-20

### 新增 🎉

#### 云端发布功能
- **云端分享** - 将HTML项目发布到云端，生成可访问的链接
- **链接有效期** - 可设置链接过期时间（7天/30天/90天/永不过期）
- **访问统计** - 记录访问次数、独立访客、来源、每日趋势等数据
- **访问密码** - Pro 用户可为已发布链接设置访问密码（bcrypt 存储）
- **到期自定义** - Pro 用户可配置到期后跳转 URL / 自定义消息 / 默认 App 引导
- **访问日志** - 查看每条访问的脱敏 IP、UA、来源、访问时间
- **发布历史管理** - 记录所有发布历史，方便追踪和管理

#### 发布中心
- **统一发布入口** - 全新的发布中心界面，整合所有发布方式
- **多种发布方式** - 本地网络分享、云端发布、GitHub Pages
- **快速操作** - 一键生成二维码、分享链接、导出Zip
- **发布状态展示** - 实时显示项目发布状态和文件信息

#### GitHub Pages 发布
- **GitHub Pages集成** - 支持将项目发布到GitHub Pages
- **Token认证** - 使用GitHub Personal Access Token进行认证（Keychain 安全存储）
- **多文件支持** - 自动上传所有项目文件到GitHub仓库
- **发布配置** - 支持配置用户名、仓库名、分支等

#### 云端项目管理
- **云端项目列表** - 查看所有已发布的云端项目
- **过期管理** - 管理链接有效期和过期状态
- **访问统计详情** - 查看详细的访问数据和趋势
- **停止分享** - 随时停止已发布的链接
- **链接搜索** - 搜索已发布的链接和项目

#### 导出功能
- **Zip导出** - 将项目导出为Zip文件，方便备份和分享
- **批量导出** - 支持导出所有项目
- **多文件支持** - 自动包含所有HTML/CSS/JS/图片文件

#### 订阅系统
- **Pro订阅** - 一次性买断（Lifetime）
- **免费限制** - 免费用户每月可发布 **3 次**，发布后 1 小时过期
- **Pro特权** - 无限发布次数、可设置访问密码、可自定义到期跳转、可选 7天/30天/90天/永不过期

#### 多语言支持
- **中文支持** - 完整的中文本地化
- **英文支持** - 完整的英文本地化
- **多语言切换** - 支持在设置中切换语言

### 改进 ✨
- **DocumentManager** - 添加云端信息管理功能
- **HTMLProject模型** - 添加cloudUrl、cloudId、expiresAt、visitCount、hasPassword等字段
- **ProjectFile模型** - 支持二进制数据（图片/字体等）
- **发布流程** - 优化发布流程，支持自定义配置
- **发布结果页** - 全新的发布结果界面，支持二维码、链接切换、分享
- **网络监控** - 添加网络状态监控功能
- **错误处理** - 完善网络错误处理和用户提示
- **并发安全** - 修复Swift 6并发安全问题

### 文档 📚
- 添加 `doc/DEPLOYMENT.md` - Dokploy 自动部署 + 手动 fallback + DB 迁移
- 添加 `doc/API.md` - 后端 API 全量参考（鉴权 / 端点 / 错误码 / 数据库 schema）
- 添加 `doc/SHARING_GUIDE.md` - 分享功能使用指南
- 添加 `doc/QUICK_START.md` - 5分钟快速上手指南
- 添加 `doc/PROJECT_SUMMARY.md` - 项目结构与功能总结
- 添加 `doc/CHANGELOG.md` - 本更新日志

## [1.0.0] - 2024-04-22

### 新增 🎉
- **实时HTML预览** - 编辑即预览，350ms延迟
- **代码编辑器** - 等宽字体，自动禁用自动更正
- **多设备视口** - iPhone、iPad、Desktop三种预览尺寸
- **文档管理** - 创建、保存、复制、删除多个HTML文档
- **自动保存** - 所有文档自动保存到本地存储
- **快速插入工具栏** - 一键插入常用HTML标签
- **模板库** - 4个预设模板快速开始
  - 空白页面
  - 响应式布局
  - 登录表单
  - CSS动画演示
- **导入/导出** - 从Files应用导入，通过Share Sheet分享
- **分屏视图** - iPad上左右分屏显示编辑器和预览
- **自适应布局** - 针对iPhone和iPad优化
- **视图模式** - iPhone上可切换编辑器、预览、分屏三种模式
- **设备框架模拟** - 显示设备图标和尺寸
- **暗色模式** - 自动适应系统外观
- **语法高亮** - HTML标签、属性、注释高亮显示
- **行号显示** - 可选的代码行号
- **撤销/重做** - 支持50步历史记录
- **查找替换** - 搜索和批量替换功能
- **控制台** - 捕获JavaScript日志和错误
- **代码格式化** - 基础的HTML格式化功能
- **引导页** - 首次使用的精美引导界面
- **设置页面** - 编辑器和预览的个性化设置

### 技术细节 🔧
- **最低iOS版本**: iOS 17.0
- **框架**: SwiftUI + UIKit
- **Web引擎**: WKWebView
- **存储**: UserDefaults
- **语言**: Swift

---

## 版本说明

### 版本号格式
- **主版本号（Major）**: 不兼容的API修改
- **次版本号（Minor）**: 向下兼容的功能性新增
- **修订号（Patch）**: 向下兼容的问题修正

### 变更类型
- **新增（Added）**: 新功能
- **改进（Changed）**: 现有功能的变更
- **弃用（Deprecated）**: 即将移除的功能
- **移除（Removed）**: 已移除的功能
- **修复（Fixed）**: 任何bug修复
- **安全（Security）**: 安全相关的修复

---

## 路线图

### v1.1.0 - 预览体验优化（已完成 ✅）
- [x] 全屏预览模式
- [x] 本地网络分享
- [x] 二维码生成
- [x] 实时同步更新
- [x] 横屏/竖屏切换
- [x] 多设备视口

### v1.2.0 - 项目管理增强（已完成 ✅）
- [x] 文件夹功能
- [x] 搜索和排序
- [x] 批量操作
- [x] 文档统计信息
- [x] 收藏功能

### v1.3.0 - 编辑器增强（已完成 ✅）
- [x] 代码补全
- [x] 快速插入工具栏
- [x] 代码格式化
- [x] 查找替换
- [x] 撤销/重做
- [x] 多文件支持

### v2.0.0 - 云端能力（已完成 ✅）
- [x] 云端分享链接
- [x] 访问统计与趋势
- [x] 发布历史管理
- [x] GitHub Pages发布
- [x] Zip导出
- [x] 订阅系统
- [x] 数据库持久化（替代原 /tmp JSON 存储）

### v3.0.0 - 架构整理（已完成 ✅）
- [x] 统一 HMAC 鉴权（所有 API 强制）
- [x] 数据库迁移到 MySQL（utf8mb4）
- [x] IP 匿名化（GDPR 合规）
- [x] 访问密码 bcrypt 加密
- [x] 多端配置统一（free_user_monthly_publish_limit = 3）

### v3.2.0 - 死代码清理（已完成 ✅）
- [x] 数据库未实现表/视图/字段清理
- [x] iOS 死模型 / 死状态 / 死 UI 清理
- [x] API 死端点 / 死字段清理
- [x] 文档与代码同步

---

## 反馈与贡献

### 报告问题
如果你发现了bug或有功能建议，请通过以下方式反馈：
- 📧 Email: fengezhao@hotmail.com
- 🐛 在设置中找到"反馈"选项
- ⭐ 在App Store评论中告诉我们

### 贡献代码
欢迎提交Pull Request！请确保：
1. 代码符合Swift风格指南
2. 添加必要的注释
3. 更新相关文档
4. 通过所有测试

---

**感谢使用 Code Editor – HTML & Preview！** 🎉
