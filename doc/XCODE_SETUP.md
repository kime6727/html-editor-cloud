# Xcode 项目设置说明

## ✅ 问题已解决

**问题**: `Cannot find type 'LocalHTMLServer' in scope`

**原因**: 新创建的 Swift 文件没有被添加到 Xcode 项目中

**解决方案**: 已更新 `project.pbxproj` 文件，添加了以下文件：
- ✅ `LocalHTMLServer.swift`
- ✅ `QRCodeGenerator.swift`
- ✅ `SharePreviewView.swift`

## 🔧 如何验证

### 方法1：在 Xcode 中检查

1. 打开 Xcode 项目
2. 在左侧项目导航器中，应该能看到三个新文件：
   - LocalHTMLServer.swift
   - QRCodeGenerator.swift
   - SharePreviewView.swift
3. 如果看不到，请关闭 Xcode 并重新打开

### 方法2：清理并重新编译

```bash
# 在终端中执行
cd /path/to/HTMLPreview

# 清理构建
rm -rf ~/Library/Developer/Xcode/DerivedData/HTMLPreview-*

# 在 Xcode 中
# Product -> Clean Build Folder (Shift + Cmd + K)
# Product -> Build (Cmd + B)
```

## 📋 项目文件结构

现在项目应该包含以下 Swift 文件：

```
HTMLPreview/
├── HTMLPreviewApp.swift          ✅
├── AppRouter.swift                ✅
├── ContentView.swift              ✅
├── Models.swift                   ✅
├── DocumentManager.swift          ✅
├── EnhancedHTMLEditorView.swift   ✅
├── EditorToolbarView.swift        ✅
├── HTMLPreviewView.swift          ✅
├── CodeFormatter.swift            ✅
├── SearchReplaceView.swift        ✅
├── OnboardingView.swift           ✅
├── SettingsView.swift             ✅
├── LocalHTMLServer.swift          ✅ 新增
├── QRCodeGenerator.swift          ✅ 新增
├── SharePreviewView.swift         ✅ 新增
├── Assets.xcassets/               ✅
└── Info.plist                     ✅
```

## 🚨 如果问题仍然存在

### 步骤1：手动添加文件到 Xcode

1. 在 Xcode 中，右键点击项目根目录
2. 选择 "Add Files to HTMLPreview..."
3. 选择以下文件：
   - LocalHTMLServer.swift
   - QRCodeGenerator.swift
   - SharePreviewView.swift
4. 确保勾选 "Copy items if needed"
5. 确保勾选 "Add to targets: HTMLPreview"
6. 点击 "Add"

### 步骤2：检查 Target Membership

1. 选择任一新文件（如 LocalHTMLServer.swift）
2. 在右侧 File Inspector 中
3. 确保 "Target Membership" 下的 "HTMLPreview" 被勾选

### 步骤3：清理并重新编译

```bash
# 在 Xcode 中
Product -> Clean Build Folder (Shift + Cmd + K)
Product -> Build (Cmd + B)
```

## 🔍 验证编译

编译成功后，你应该能够：

1. ✅ 导入 LocalHTMLServer 类
2. ✅ 导入 QRCodeGenerator 结构体
3. ✅ 导入 SharePreviewView 视图
4. ✅ 无编译错误
5. ✅ 无编译警告

## 📱 运行应用

```bash
# 在 Xcode 中
1. 选择目标设备（iPhone 或 iPad）
2. 点击运行按钮 ▶️
3. 应用应该正常启动
4. 点击顶部的 QR 码图标测试分享功能
```

## 🐛 常见问题

### Q1: 文件显示为红色？
**A**: 文件路径不正确，需要重新添加文件到项目

### Q2: 编译时找不到文件？
**A**: 检查 Target Membership 是否正确设置

### Q3: 导入语句报错？
**A**: 清理构建文件夹并重新编译

### Q4: 模拟器无法运行？
**A**: 分享功能需要真机测试，模拟器可能无法获取正确的 IP 地址

## ✅ 验证清单

- [ ] 三个新文件在项目导航器中可见
- [ ] 文件不是红色（路径正确）
- [ ] Target Membership 已勾选
- [ ] 编译无错误
- [ ] 编译无警告
- [ ] 应用可以运行
- [ ] 分享功能可以打开

## 📞 需要帮助？

如果问题仍然存在，请提供以下信息：

1. Xcode 版本
2. macOS 版本
3. 完整的错误信息
4. 项目导航器的截图

---

**更新时间**: 2024-04-22  
**状态**: ✅ 已解决
