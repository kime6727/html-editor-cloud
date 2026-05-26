# 云端发布访问问题 - 快速修复指南

## 问题诊断

✅ **文件上传成功** - pub目录下有文件  
✅ **数据库记录正常** - 项目信息已保存  
❌ **访问失败** - 因为配置指向远程服务器，但文件在本地

## 根本原因

`ios/AppConfig.swift` 中的配置指向远程服务器：
```swift
static let apiBaseURL = "https://html.weburl.cloudns.be/"
```

但你的文件实际上传到了**本地数据库和本地文件系统**，所以访问远程URL当然找不到文件。

## 解决方案

### 方案A：本地开发测试（推荐）

#### 步骤1：启动本地服务器

```bash
# 在项目根目录执行
php -S localhost:8080
```

保持这个终端窗口打开！

#### 步骤2：验证服务器

在浏览器打开：
- http://localhost:8080/pub/1c906161/index.html

应该能看到你的"CSS 动画"项目。

#### 步骤3：修改iOS配置（已完成）

`ios/AppConfig.swift` 已经修改为：
```swift
static let apiBaseURL = "http://localhost:8080/backend/"
static let publishAPIBaseURL = "http://localhost:8080"
```

#### 步骤4：重新构建iOS应用

在Xcode中：
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Run (⌘R)

#### 步骤5：测试发布

1. 在iOS应用中创建或打开一个项目
2. 点击发布
3. 发布成功后，点击返回的URL
4. 应该能在应用内预览中看到你的项目

### 方案B：部署到远程服务器

如果你想使用远程服务器 `https://html.weburl.cloudns.be/`：

#### 步骤1：上传后端文件

```bash
# 上传所有后端文件到服务器
scp -r backend/* user@html.weburl.cloudns.be:/path/to/backend/
scp -r pub/* user@html.weburl.cloudns.be:/path/to/pub/
```

#### 步骤2：配置服务器

确保服务器上：
1. PHP 7.4+ 已安装
2. MySQL 已配置
3. .env 文件配置正确
4. pub 目录可写（chmod 755）

#### 步骤3：导入数据库

```bash
# 导出本地数据库
mysqldump -u root -p html_editor > backup.sql

# 导入到远程服务器
mysql -h html.weburl.cloudns.be -u user -p database_name < backup.sql
```

#### 步骤4：测试远程服务器

```bash
curl https://html.weburl.cloudns.be/backend/test_publish.php
```

#### 步骤5：恢复iOS配置

将 `ios/AppConfig.swift` 改回：
```swift
static let apiBaseURL = "https://html.weburl.cloudns.be/"
static let publishAPIBaseURL = "https://html.weburl.cloudns.be"
```

## 当前状态

✅ 本地PHP服务器已启动在 http://localhost:8080  
✅ iOS配置已修改为本地服务器  
⏳ 需要重新构建iOS应用

## 测试清单

完成以下测试确认问题已解决：

### 1. 服务器测试
```bash
# 测试静态文件访问
curl http://localhost:8080/pub/1c906161/index.html

# 测试发布API
curl http://localhost:8080/backend/test_publish.php

# 测试项目管理API（需要签名，返回403正常）
curl http://localhost:8080/backend/api/projects.php
```

### 2. iOS应用测试
- [ ] 重新构建应用
- [ ] 创建新项目
- [ ] 发布项目
- [ ] 点击返回的URL
- [ ] 在应用内预览中查看
- [ ] 复制URL在Safari中打开

### 3. 功能测试
- [ ] 发布成功显示URL
- [ ] URL可以访问
- [ ] 内容显示正确
- [ ] 样式加载正常
- [ ] 图片显示正常（如果有）

## 常见问题

### Q1: 服务器启动后立即退出
**A**: 检查8080端口是否被占用
```bash
lsof -i :8080
# 如果被占用，使用其他端口
php -S localhost:8081
# 然后修改AppConfig中的端口号
```

### Q2: iOS应用仍然访问不了
**A**: 确保：
1. 服务器正在运行（终端窗口不要关闭）
2. 已经Clean Build Folder
3. 已经重新运行应用
4. 检查Xcode控制台的错误信息

### Q3: 显示"网络错误"
**A**: 检查：
1. iOS模拟器可以访问localhost
2. 如果使用真机，需要使用局域网IP
3. 防火墙是否阻止了连接

### Q4: 返回403错误
**A**: 这是正常的，说明服务器在运行，只是API需要签名验证

### Q5: 文件上传成功但访问404
**A**: 检查：
```bash
# 确认文件确实存在
ls -la pub/项目ID/

# 确认服务器能访问
curl http://localhost:8080/pub/项目ID/index.html
```

## 下一步

1. **立即执行**：
   ```bash
   # 确保服务器在运行
   php -S localhost:8080
   ```

2. **在Xcode中**：
   - Clean Build Folder
   - Run

3. **测试发布**：
   - 创建简单的HTML项目
   - 点击发布
   - 验证可以访问

4. **如果成功**：
   - 继续使用本地开发
   - 或者部署到远程服务器

## 技术说明

### 为什么会出现这个问题？

你的开发环境是**混合模式**：
- **iOS应用** 配置指向远程服务器
- **后端API** 实际运行在本地
- **数据库** 在本地
- **文件存储** 在本地

所以：
1. iOS发布请求 → 远程服务器（失败或成功但文件不在那里）
2. 或者请求到本地 → 文件保存到本地
3. 但返回的URL是远程的 → 访问失败

### 正确的配置

**开发环境**（推荐）：
- iOS配置 → localhost
- 后端 → localhost
- 数据库 → localhost
- 文件 → localhost

**生产环境**：
- iOS配置 → 远程服务器
- 后端 → 远程服务器
- 数据库 → 远程服务器
- 文件 → 远程服务器

不要混用！

## 验证成功的标志

当你看到以下情况，说明问题已解决：

1. ✅ 发布成功，显示URL
2. ✅ URL格式：`http://localhost:8080/pub/xxxxx/index.html`
3. ✅ 点击URL能在应用内预览
4. ✅ 复制URL在Safari中能打开
5. ✅ 内容和样式都正确显示

---

**当前服务器状态**: 🟢 运行中 (http://localhost:8080)  
**配置状态**: ✅ 已修改为本地  
**下一步**: 重新构建iOS应用并测试
