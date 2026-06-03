# Code Editor – HTML & Preview - 项目总结

## 📋 产品元信息

| 项目 | 值 |
|------|---|
| **App 名称** | Code Editor – HTML & Preview |
| **Bundle ID** | `com.niceapp.htmleditor` |
| **Apple ID** | `6764022927` |
| **App Store（中国区）** | https://apps.apple.com/CN/app/id6764022927 |
| **App 官网** | https://page.niceapp.eu.cc/apps/code_editor |
| **后端仓库** | https://github.com/kime6727/html-editor-cloud |
| **后端部署** | Dokploy |
| **后端域名** | https://html.niceapp.eu.cc |
| **订阅 Product ID** | `CodeEditor_999`（Lifetime） |
| **支持邮箱** | fengezhao@hotmail.com |

---

## 平台与基础设施

| 项目 | 值 |
|------|---|
| **iOS 最低版本** | iOS 17.0 |
| **客户端语言** | Swift（SwiftUI + UIKit） |
| **客户端架构** | MVVM + Combine + ObservableObject |
| **本地存储** | iOS FileManager + UserDefaults + Keychain |
| **本地网络共享** | Network.framework `NWListener`（HTTPS 弱/自签证书，端口动态） |
| **Web 渲染** | WKWebView |
| **后端语言** | PHP 7.4+（兼容 MySQL 5.7 / 8.0） |
| **后端数据库** | MySQL（utf8mb4，pconnect 长连接） |
| **后端架构** | 单体 API + 静态资源直出（Nginx + PHP-FPM） |
| **云端发布流程** | iOS Multipart Upload → PHP `publish.php` → 写 `pub/{project_id}/index.html` |
| **HMAC 鉴权** | SHA-256 over `apiKey + timestamp`，5 分钟时间窗 |
| **GitHub 发布** | 客户端直连 GitHub Contents API（无需后端代理） |

---

## 📜 协议与支持链接

| 项目 | 链接 |
|------|------|
| **用户服务协议** | https://page.niceapp.eu.cc/index.php/archives/User-Service-Agreement.html |
| **隐私政策** | https://page.niceapp.eu.cc/index.php/archives/Privacy-Policy.html |
| **在线客服** | https://page.niceapp.eu.cc/index.php/archives/13.html |
| **支持邮箱** | fengezhao@hotmail.com |

> ⚠️ **安全提醒**：Personal Access Token（GitHub）等任何云端凭证**不要**写入仓库、文档、Info.plist。使用 Keychain 或后端代理签发短期 token。如已泄露请立即到 https://github.com/settings/tokens 撤销。

---

## 📦 项目结构

```
HTMLPreview/
│
├── 📱 应用核心
│   ├── HTMLPreviewApp.swift          # 应用入口
│   ├── AppRouter.swift                # 路由管理
│   ├── ContentView.swift              # 主界面
│   ├── MainTabView.swift              # 主标签视图
│   ├── AppConfig.swift                # 应用配置
│   └── Info.plist                     # 应用配置
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
│   ├── EmptyStateView.swift            # 空状态视图 🆕
│   └── ToastManager.swift             # Toast提示 🆕
│
├── ✏️ 编辑器
│   ├── EnhancedHTMLEditorView.swift   # HTML编辑器
│   ├── AutoCompleteManager.swift      # 代码补全管理器 🆕
│   └── AutoCompleteView.swift         # 代码补全视图 🆕
│
├── 👁️ 预览
│   ├── HTMLPreviewView.swift          # HTML预览
│   └── FullScreenPreviewView.swift    # 全屏预览 🆕
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
│   ├── HapticManager.swift            # 触觉反馈管理 🆕
│   ├── LanguageManager.swift          # 多语言管理 🆕
│   ├── ToastTypes.swift               # Toast类型 🆕
│   └── AnimationModifiers.swift       # 动画修饰器 🆕
│
├── 🎨 资源
│   └── Assets.xcassets/               # 图片资源
│       ├── AppIcon.appiconset/
│       └── Contents.json
│
├── 📚 文档
│   ├── README.md                      # 项目说明
│   ├── CHANGELOG.md                   # 更新日志
│   ├── QUICK_START.md                 # 快速开始
│   ├── SHARING_GUIDE.md               # 分享指南
│   ├── PROJECT_SUMMARY.md             # 项目总结
│   ├── requirements.md                # 完整需求
│   ├── DEPLOYMENT.md                  # 部署指南 🆕
│   └── API.md                         # 后端 API 参考 🆕
│
└── 🏗️ 项目配置
    └── HTMLPreview.xcodeproj/         # Xcode项目
```

## 📊 项目统计

### 代码统计

| 类型 | 文件数 | 代码行数 | 注释行数 |
|------|--------|----------|----------|
| Swift | 50+ | ~8000+ | ~1000+ |
| Markdown | 10+ | - | ~25000字 |
| HTML | 1 | ~200 | ~50 |
| PHP | 3 | ~500 | ~100 |
| Plist | 1 | ~50 | - |
| **总计** | **65+** | **~8750+** | **~1150+** |

### 功能模块

| 模块 | 文件数 | 功能数 | 完成度 |
|------|--------|--------|--------|
| 核心应用 | 5 | 12 | 100% |
| 用户界面 | 18 | 50+ | 100% |
| 编辑器 | 3 | 10 | 100% |
| 预览 | 2 | 8 | 100% |
| 数据管理 | 5 | 20 | 100% |
| 云端服务 | 6 | 25 | 100% |
| 工具类 | 10 | 30 | 100% |
| **总计** | **49** | **155+** | **100%** |

## 🎯 核心功能

### 1. HTML编辑 ✅
- 实时预览
- 语法高亮
- 行号显示
- 撤销/重做
- 查找替换
- 快速插入标签
- 代码格式化
- 代码补全
- 多文件支持

### 2. 预览功能 ✅
- 多设备视口（iPhone/iPad/Desktop）
- 设备框架模拟
- JavaScript控制台
- 实时更新
- 错误提示
- 全屏预览

### 3. 项目管理 ✅
- 创建/删除/复制项目
- 自动保存
- 导入/导出
- 模板库（15+个模板）
- 多项目切换
- 文件夹组织
- 收藏功能
- 搜索和排序

### 4. 分享功能 ✅
- 本地HTTP服务器
- 二维码生成
- 实时同步更新
- WiFi网络分享
- 隐私安全

### 5. 云端发布 ✅
- 云端分享
- 链接有效期（Pro：7天/30天/90天/永不过期；免费：固定 1 小时）
- 访问统计（独立访客 / 每日趋势 / Top 来源）
- 访问日志（脱敏 IP / UA / 访问时间）
- 发布历史管理
- Pro 用户支持访问密码保护（bcrypt 存储）
- Pro 用户支持自定义到期行为（跳转 URL / 自定义消息 / App 引导）

### 6. GitHub Pages ✅
- GitHub Pages集成
- Token认证
- 多文件上传
- 发布配置

### 7. 导出功能 ✅
- Zip导出
- 批量导出
- 多文件支持

### 8. 订阅系统 ✅
- Pro 一次性买断（Lifetime）
- 免费限制：每月 3 次发布，单次发布 1 小时过期
- Pro 特权：无限发布 / 访问密码 / 自定义有效期 / 自定义到期行为

### 9. 多语言支持 ✅
- 中文
- 英文
- 多语言切换

### 10. 用户体验 ✅
- 精美的引导页
- 自适应布局
- 暗色模式
- 设置选项
- 错误处理
- Toast提示
- 触觉反馈

## 🏆 核心优势

### 1. 快速分享 ⚡
- **本地网络**: 无需上传，扫码即看
- **云端发布**: 永久链接，随时访问
- **GitHub Pages**: 开发者友好，永久存储
- **实时更新**: 编辑即同步

### 2. 隐私安全 🔒
- **本地网络**: 数据不离开WiFi
- **云端加密**: HMAC-SHA256签名验证
- **访问密码**: 保护敏感内容
- **即停即关**: 关闭即停止服务

### 3. 跨平台 🌐
- **支持所有设备**: iOS/Android/Windows/Mac
- **支持所有浏览器**: Safari/Chrome/Firefox/Edge
- **无需安装**: 浏览器直接访问
- **响应式**: 自适应各种屏幕

### 4. 品牌感 🎨
- **精美 UI** - 现代化的用户界面
- **多语言** - 支持中文和英文
- **Pro 访问密码** - bcrypt 存储，5 次错误锁定 15 分钟

### 5. 零成本 💰
- **免费使用**: 基础功能完全免费
- **Pro订阅**: 高级功能按需购买
- **无广告**: 纯净体验
- **开源**: MIT许可证

## 🎨 技术亮点

### 1. 网络编程
```swift
// 使用 Network.framework 实现HTTP服务器
let listener = try NWListener(using: .tcp)
listener.newConnectionHandler = { connection in
    // 处理HTTP请求
}
```

### 2. 二维码生成
```swift
// 使用 CoreImage 生成高清QR码
let filter = CIFilter(name: "CIQRCodeGenerator")
filter?.setValue(data, forKey: "inputMessage")
```

### 3. 云端发布
```swift
// 使用 HMAC-SHA256 签名验证
let signature = HMAC<SHA256>.authenticationCode(
    for: Data(message.utf8), 
    using: SymmetricKey(data: Data(apiKey.utf8))
)
```

### 4. 状态管理
```swift
// 使用 @Published 和 @State 管理状态
@Published var isRunning = false
@Published var serverURL: String?
```

### 5. 并发安全
```swift
// 使用 @MainActor 确保UI更新安全
@MainActor
class CloudService: ObservableObject {
    // ...
}
```

## 📱 使用场景

### 1. 教学演示 👨‍🏫
```
老师在iPad上编辑代码
    ↓
生成二维码投影到大屏幕
    ↓
学生扫码在自己设备上查看
    ↓
老师修改代码，学生实时看到变化
```

### 2. 多设备测试 📱💻
```
在主设备上开启分享
    ↓
在iPhone、iPad、Mac上同时打开预览
    ↓
修改CSS，所有设备同步更新
    ↓
快速验证不同屏幕尺寸的效果
```

### 3. 团队协作 🤝
```
使用云端发布功能
    ↓
复制访问链接分享给同事
    ↓
同事点击链接即可查看
    ↓
根据反馈实时调整
```

### 4. 客户演示 💼
```
完成项目编辑
    ↓
使用云端发布
    ↓
复制访问链接
    ↓
发送链接给客户
    ↓
根据客户意见现场修改并重新发布
```
### 5. 个人作品集 🎨
```
完成作品编辑
    ↓
使用GitHub Pages发布
    ↓
获得永久链接
    ↓
添加到简历或社交媒体
```

## 🚀 未来计划

### 已完成 ✅
- [x] 本地网络分享与二维码生成
- [x] 云端发布
- [x] 访问密码（Pro，bcrypt）+ 链接有效期管理
- [x] 访问统计 + 访问日志 + 7日趋势
- [x] Pro 自定义到期行为（跳转 / 消息 / 引导）
- [x] GitHub Pages 集成（Keychain 存 Token）
- [x] Zip 导出 / 批量操作
- [x] 订阅系统（Lifetime）
- [x] 多语言支持（中 / 英）
- [x] 文件夹管理 / 收藏 / 搜索
- [x] 代码补全 / 语法高亮
- [x] 模板库（15+ 模板）
- [x] HMAC-SHA256 全 API 鉴权
- [x] MySQL 持久化 + IP 匿名化（GDPR）

### 进行中 🚧
- [ ] iCloud同步
- [ ] 协作功能

### 计划中 📋
- [ ] 更多语言支持（日语、韩语、法语等）
- [ ] 代码片段库
- [ ] Emmet支持
- [ ] 多光标编辑
- [ ] 正则搜索
- [ ] 主题切换
- [ ] 预览截图导出
- [ ] 可拖拽分隔条

## 📞 反馈与支持

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
