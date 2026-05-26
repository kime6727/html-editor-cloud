#!/bin/bash
# 准备生产环境部署包
# 自动调整路径配置以适应线上目录结构

set -e  # 遇到错误立即退出

echo "=========================================="
echo "  准备生产环境部署包"
echo "  目标: https://html.weburl.cloudns.be"
echo "=========================================="
echo ""

# 清理旧的部署包
if [ -d "deploy_package" ]; then
    echo "🗑️  清理旧的部署包..."
    rm -rf deploy_package
fi

# 创建部署目录
echo "📁 创建部署目录..."
mkdir -p deploy_package/pub

# 复制后端文件
echo "📋 复制后端文件..."
cp -r backend/* deploy_package/

# 复制pub目录的.htaccess
if [ -f "backend/pub/.htaccess" ]; then
    cp backend/pub/.htaccess deploy_package/pub/
fi

# 修改路径配置
echo "🔧 调整路径配置..."

# 1. 修改 publish.php
echo "   - publish.php"
sed -i.bak "s|\$scriptDir . '/../pub/'|\$scriptDir . '/pub/'|g" deploy_package/publish.php
sed -i.bak "s|__DIR__ . '/../pub/'|__DIR__ . '/pub/'|g" deploy_package/publish.php

# 2. 修改 api/projects.php
echo "   - api/projects.php"
sed -i.bak "s|__DIR__ . '/../../pub/'|__DIR__ . '/../pub/'|g" deploy_package/api/projects.php

# 3. 修改 redirect.php
echo "   - redirect.php"
sed -i.bak "s|__DIR__ . '/../pub/'|__DIR__ . '/pub/'|g" deploy_package/redirect.php

# 4. 修改 delete.php
echo "   - delete.php"
sed -i.bak "s|__DIR__ . '/../pub/'|__DIR__ . '/pub/'|g" deploy_package/delete.php

# 5. 修改 stats.php（如果有路径引用）
if grep -q "../pub/" deploy_package/stats.php 2>/dev/null; then
    echo "   - stats.php"
    sed -i.bak "s|__DIR__ . '/../pub/'|__DIR__ . '/pub/'|g" deploy_package/stats.php
fi

# 删除备份文件
find deploy_package -name "*.bak" -delete

# 检查.env文件
if [ ! -f "deploy_package/.env" ]; then
    echo "⚠️  创建.env模板..."
    cat > deploy_package/.env << 'EOF'
# 数据库配置
DB_HOST=localhost
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASS=your_database_password

# API密钥
PUBLISH_API_KEY=f7a2b9c3e1d6e5f8a0b9c2d1e4f7a2b9
EOF
    echo "   ✅ 已创建 .env 模板"
    echo "   ⚠️  请编辑 deploy_package/.env 填入真实的数据库信息！"
else
    echo "✅ .env 文件已存在"
fi

# 创建部署说明
cat > deploy_package/DEPLOY_INSTRUCTIONS.txt << 'EOF'
===========================================
生产环境部署说明
===========================================

1. 上传所有文件到服务器根目录
   目标: https://html.weburl.cloudns.be 绑定的目录

2. 编辑 .env 文件
   填入真实的数据库配置信息

3. 设置权限
   chmod 755 *.php
   chmod 755 -R api/
   chmod 755 -R database/
   chmod 777 pub/
   chmod 600 .env

4. 导入数据库
   mysql -u user -p database_name < schema.sql

5. 测试
   curl https://html.weburl.cloudns.be/test_publish.php

6. 验证
   - 访问 https://html.weburl.cloudns.be/test_publish.php
   - 在iOS应用中测试发布功能

===========================================
EOF

# 创建压缩包
echo "📦 创建压缩包..."
cd deploy_package
tar -czf ../production_deploy.tar.gz .
cd ..

# 显示文件列表
echo ""
echo "=========================================="
echo "✅ 部署包准备完成！"
echo "=========================================="
echo ""
echo "📦 压缩包: production_deploy.tar.gz"
echo "📁 目录: deploy_package/"
echo ""
echo "📋 包含文件:"
ls -lh deploy_package/ | head -20
echo ""
echo "📝 下一步操作:"
echo ""
echo "1️⃣  编辑数据库配置:"
echo "   nano deploy_package/.env"
echo ""
echo "2️⃣  上传到服务器:"
echo "   scp production_deploy.tar.gz user@server:/path/to/html.weburl.cloudns.be/"
echo ""
echo "3️⃣  在服务器上解压:"
echo "   tar -xzf production_deploy.tar.gz"
echo ""
echo "4️⃣  设置权限:"
echo "   chmod 777 pub/"
echo "   chmod 600 .env"
echo ""
echo "5️⃣  测试:"
echo "   curl https://html.weburl.cloudns.be/test_publish.php"
echo ""
echo "=========================================="
