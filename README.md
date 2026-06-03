# Code Editor – HTML & Preview - 移动端HTML编辑器与云端发布平台

一款专业的iOS HTML编辑与云端发布工具，让开发者、设计师和创作者能够在移动设备上快速编写、预览和发布HTML项目。

## 📋 产品元信息

| 项目 | 值 |
|------|---|
| **App 名称** | Code Editor – HTML & Preview |
| **Bundle ID** | `com.niceapp.htmleditor` |
| **Apple ID** | `6764022927` |
| **App Store（中国区）** | https://apps.apple.com/CN/app/id6764022927 |
| **App 官网** | https://page.niceapp.eu.cc/apps/code_editor |
| **后端仓库** | https://github.com/kime6727/html-editor-cloud |
| **后端部署方式** | Dokploy |
| **后端绑定域名** | https://html.niceapp.eu.cc |
| **最低 iOS 版本** | iOS 17.0 |
| **开发语言** | Swift（SwiftUI + UIKit） |
| **Web 引擎** | WKWebView |
| **后端语言** | PHP + MySQL |
| **本地化** | 中文、英文 |

### 订阅 / Paywall 配置

| 项目 | 值 |
|------|---|
| **订阅商品类型** | 一次性买断（Lifetime） |
| **Product ID** | `CodeEditor_999` |

### 协议与支持

| 项目 | 链接 |
|------|------|
| **用户服务协议** | https://page.niceapp.eu.cc/index.php/archives/User-Service-Agreement.html |
| **隐私政策** | https://page.niceapp.eu.cc/index.php/archives/Privacy-Policy.html |
| **在线客服** | https://page.niceapp.eu.cc/index.php/archives/13.html |
| **联系邮箱** | fengezhao@hotmail.com |

### GitHub 集成

| 项目 | 值 |
|------|---|
| **GitHub 用户名** | `@kime6727` |
| **SSH Key 名称** | `aicode_2` |
| **GitHub PAT** | 🔒 **请勿提交到仓库 / 文档中**——从 Keychain、`xcodebuild` 注入或后端服务下发 |

> ⚠️ **安全提示**：Personal Access Token (PAT) 属于敏感凭证，仅在本地构建机或 CI Secret 中保存，**不要**写入 Info.plist、.env、代码或本文档。若已泄露，请立即到 https://github.com/settings/tokens 撤销并重新生成。

## 核心功能

### 📝 代码编辑
- **实时HTML预览** - 编辑即预览，350ms延迟
- **多文件支持** - 支持HTML、CSS、JavaScript、JSON、Markdown等多种文件类型
- **代码补全** - 智能代码补全和自动闭合标签
- **快速插入工具栏** - 一键插入常用HTML标签
- **撤销/重做** - 支持50步历史记录
- **查找替换** - 搜索和批量替换功能
- **代码格式化** - 基础的HTML格式化功能
- **语法高亮** - HTML标签、属性、注释高亮显示
- **行号显示** - 可选的代码行号

### 👁️ 预览功能
- **多设备视口** - iPhone、iPad、Desktop三种预览尺寸
- **实时同步更新** - 编辑代码时预览自动刷新
- **控制台** - 捕获JavaScript日志和错误
- **全屏预览** - 全屏查看预览效果
- **设备框架模拟** - 显示设备图标和尺寸

### 📁 项目管理
- **多项目管理** - 创建、保存、复制、删除多个HTML项目
- **文件夹功能** - 使用文件夹组织项目
- **自动保存** - 所有项目自动保存到本地存储
- **收藏功能** - 收藏常用项目
- **搜索和排序** - 快速查找项目，支持多种排序方式
- **导入/导出** - 从Files应用导入，通过Share Sheet分享
- **Zip导出** - 将项目导出为Zip文件，方便备份和分享

### 🌐 云端发布
- **云端分享** - 将项目发布到云端，生成永久可访问的链接
- **链接有效期** - 可设置链接过期时间（7天/30天/90天/永不过期）
- **访问统计** - 记录访问次数、独立访客等数据
- **发布历史管理** - 记录所有发布历史，方便追踪和管理
- **云端项目管理** - 管理已发布的云端项目，支持停止分享、设置密码等

### 📱 本地网络分享
- **本地HTTP服务器** - 启动本地服务器分享预览
- **二维码生成** - 自动生成QR码，扫码即可访问
- **实时同步** - 编辑代码时，所有连接的设备自动刷新
- **隐私安全** - 代码只在本地WiFi网络传输

### 🐙 GitHub Pages 发布
- **GitHub Pages集成** - 支持将项目发布到GitHub Pages
- **Token认证** - 使用GitHub Personal Access Token进行认证
- **多文件支持** - 自动上传所有项目文件到GitHub仓库
- **发布配置** - 支持配置用户名、仓库名、分支等

### 🎨 模板库
- **丰富模板** - 预设多种模板快速开始
  - 空白页面
  - 完整网站
  - 响应式布局
  - 登录表单
  - CSS动画
  - 点击游戏
  - 贪吃蛇
  - 打砖块
  - 记忆匹配
  - 粒子效果
  - 数字时钟
  - 3D立方体
  - 打字机效果
  - 待办事项
  - 天气卡片

### 💎 订阅系统
- **Pro订阅** - 支持应用内购买（一次性买断 Lifetime）
- **免费限制** - 免费用户每月可发布 **3 次**（由 `system_config.free_user_monthly_publish_limit` 控制）
- **Pro特权** - 无发布次数限制、可设置访问密码、可设置到期自定义跳转

### 🌍 多语言支持
- **中文** - 完整的中文本地化
- **英文** - 完整的英文本地化
- **多语言切换** - 支持在设置中切换语言

### 🎯 用户体验
- **自适应布局** - 针对iPhone和iPad优化
- **分屏视图** - iPad上左右分屏显示编辑器和预览
- **视图模式** - iPhone上可切换编辑器、预览、分屏三种模式
- **暗色模式** - 自动适应系统外观
- **引导页** - 首次使用的精美引导界面
- **设置页面** - 编辑器和预览的个性化设置

## 使用指南

### 快速开始

1. **创建项目** - 点击 `+` 图标创建新项目
2. **选择模板** - 从模板库中选择预设模板，或从空白开始
3. **编辑代码** - 在编辑器中编写HTML/CSS/JavaScript
4. **实时预览** - 在预览面板中查看效果
5. **发布分享** - 使用发布中心将项目发布到云端或GitHub Pages

### 发布项目

#### 云端发布
1. 打开项目，点击"发布"按钮
2. 选择"云端发布"
3. 设置链接有效期（可选）
4. 点击"发布"，等待上传完成
5. 分享生成的链接或二维码

#### GitHub Pages 发布
1. 首次使用需要配置GitHub信息
2. 输入用户名、仓库名、分支和Access Token
3. 验证配置并保存
4. 选择项目，点击"GitHub Pages"发布
5. 等待上传完成，访问生成的链接

#### 本地网络分享
1. 点击"本地网络分享"
2. 启动本地服务器
3. 扫描二维码或复制链接
4. 在同一WiFi下的设备访问

### 管理已发布的项目

1. 进入"设置" > "已发布的链接"
2. 查看所有已发布的项目
3. 复制链接、分享、在浏览器中打开
4. 管理云端项目（设置密码、有效期、查看统计等）
5. 停止分享或取消发布

## 技术细节

- **最低iOS版本**: iOS 17.0
- **框架**: SwiftUI + UIKit
- **Web引擎**: WKWebView
- **存储**: UserDefaults + 本地文件系统
- **网络**: Network.framework（本地HTTP服务器）
- **云端**: 自建云端API + GitHub Pages
- **语言**: Swift
- **本地化**: 中文、英文

## 隐私与安全

- **本地网络** - HTML代码仅在本地WiFi网络传输
- **云端加密** - 云端传输使用HMAC-SHA256签名验证
- **访问密码** - 支持设置访问密码保护云端项目
- **临时服务器** - 本地HTTP服务器在关闭分享后自动停止
- **IP匿名化** - 访问日志中的IP地址经过哈希处理和截断，符合GDPR要求
- **最小数据收集** - 仅收集必要的访问统计信息（访问次数、设备类型、来源页面）
- **无第三方追踪** - 不使用任何第三方分析或追踪服务
- **Token安全** - GitHub Token安全存储在Keychain中
- **数据保留** - 访问日志在90天后自动清理

## 项目结构

```
HTMLPreview/
│
├── 📱 应用核心
│   ├── HTMLPreviewApp.swift          # 应用入口
│   ├── AppRouter.swift                # 路由管理
│   ├── ContentView.swift              # 主界面
│   ├── MainTabView.swift              # 主标签视图
│   └── AppConfig.swift                # 应用配置
│
├── 🎨 用户界面
│   ├── OnboardingView.swift           # 引导页
│   ├── SettingsView.swift             # 设置页
│   ├── SharePreviewView.swift         # 分享界面
│   ├── SearchReplaceView.swift        # 查找替换
│   ├── EditorToolbarView.swift        # 编辑器工具栏
│   ├── PublishHubView.swift           # 发布中心 🆕
│   ├── PublishConfigView.swift        # 发布配置 🆕
│   ├── PublishResultView.swift        # 发布结果 🆕
│   ├── EnhancedPublishResultView.swift # 增强发布结果 🆕
│   ├── PublishedProjectsListView.swift # 已发布项目列表 🆕
│   ├── CloudProjectManagerView.swift   # 云端项目管理 🆕
│   ├── GitHubConfigView.swift          # GitHub配置 🆕
│   ├── ProjectBrowserView.swift        # 项目浏览器 🆕
│   ├── FolderBrowserView.swift         # 文件夹浏览器 🆕
│   ├── TemplatePickerView.swift        # 模板选择器 🆕
│   ├── SubscriptionView.swift          # 订阅视图 🆕
│   └── EmptyStateView.swift            # 空状态视图 🆕
│
├── ✏️ 编辑器
│   ├── EnhancedHTMLEditorView.swift   # HTML编辑器
│   ├── AutoCompleteManager.swift      # 代码补全管理器
│   └── AutoCompleteView.swift         # 代码补全视图
│
├── 👁️ 预览
│   ├── HTMLPreviewView.swift          # HTML预览
│   └── FullScreenPreviewView.swift    # 全屏预览
│
├── 💾 数据管理
│   ├── Models.swift                   # 数据模型
│   ├── DocumentManager.swift          # 文档管理
│   ├── FolderManager.swift            # 文件夹管理 🆕
│   ├── ArchiveManager.swift           # 归档管理 🆕
│   └── RatingManager.swift            # 评分管理 🆕
│
├── 🌐 云端服务
│   ├── CloudService.swift             # 云端发布服务 🆕
│   ├── CloudProjectManager.swift      # 云端项目管理 🆕
│   ├── GitHubPublishService.swift     # GitHub发布服务 🆕
│   ├── PublishedProjectsManager.swift # 已发布项目管理 🆕
│   ├── PublishHistoryManager.swift    # 发布历史管理 🆕
│   └── SubscriptionManager.swift      # 订阅管理 🆕
│
├── 🔧 工具类
│   ├── CodeFormatter.swift            # 代码格式化
│   ├── LocalHTMLServer.swift          # 本地服务器
│   ├── QRCodeGenerator.swift          # 二维码生成
│   ├── ZipExportManager.swift         # Zip导出管理 🆕
│   ├── NetworkRetryManager.swift      # 网络重试管理 🆕
│   ├── NetworkMonitor.swift           # 网络监控 🆕
│   ├── HapticManager.swift            # 触觉反馈管理 🆕
│   ├── LanguageManager.swift          # 多语言管理 🆕
│   └── ToastManager.swift             # Toast提示管理 🆕
│
├── 🎨 资源
│   └── Assets.xcassets/               # 图片资源
│       ├── AppIcon.appiconset/
│       └── Contents.json
│
├── 📚 文档（/doc）
│   ├── README.md                       # 项目说明（本文件）
│   ├── CHANGELOG.md                    # 更新日志
│   ├── QUICK_START.md                  # 快速开始
│   ├── SHARING_GUIDE.md                # 分享指南
│   ├── PROJECT_SUMMARY.md              # 项目总结
│   ├── requirements.md                 # 完整需求
│   ├── CLOUD_PUBLISH_ANALYSIS.md       # 云端发布深度分析
│   ├── DEPLOYMENT.md                   # 部署指南 🆕
│   └── API.md                          # 后端 API 参考 🆕
│
└── 🏗️ 项目配置
    └── HTMLPreview.xcodeproj/          # Xcode 工程
```

## 未来规划

### 已完成 ✅
- [x] 本地网络分享与二维码生成
- [x] 云端发布
- [x] 访问统计与发布历史
- [x] GitHub Pages集成
- [x] Zip导出功能
- [x] 订阅系统
- [x] 多语言支持
- [x] 文件夹管理
- [x] 代码补全
- [x] 模板库扩展
- [x] IP匿名化（GDPR合规）

### 进行中 🚧
- [ ] iCloud同步
- [ ] 协作功能
- [ ] 版本历史
- [ ] 评论功能
- [ ] 团队空间

### 计划中 📋
- [ ] 更多语言支持（日语、韩语、法语等）
- [ ] 代码片段库
- [ ] Emmet支持
- [ ] 多光标编辑
- [ ] 正则搜索
- [ ] 主题切换
- [ ] 预览截图导出
- [ ] 可拖拽分隔条

## 反馈与支持

### 报告问题
如果你发现了bug或有功能建议，请通过以下方式反馈：
- 📧 Email: fengezhao@hotmail.com
- 💬 在线客服: https://page.niceapp.eu.cc/index.php/archives/13.html
- 🐛 在设置中找到"反馈"选项
- ⭐ 在App Store评论中告诉我们：https://apps.apple.com/CN/app/id6764022927

### 技术支持
- 📖 查看使用指南和常见问题
- 💬 发送邮件获取技术支持
- 🌐 访问官方网站获取最新资讯：https://page.niceapp.eu.cc/apps/code_editor

### 相关链接
- 🍎 App Store: https://apps.apple.com/CN/app/id6764022927
- 📜 用户协议: https://page.niceapp.eu.cc/index.php/archives/User-Service-Agreement.html
- 🔒 隐私政策: https://page.niceapp.eu.cc/index.php/archives/Privacy-Policy.html
- 🐙 后端仓库: https://github.com/kime6727/html-editor-cloud

## 许可证

MIT License - 欢迎使用和分享！

---

**感谢使用 Code Editor – HTML & Preview！** 🎉
