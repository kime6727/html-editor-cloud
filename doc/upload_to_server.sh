#!/bin/bash
# 上传到生产服务器
# 使用前请先配置服务器信息

echo "=========================================="
echo "  上传到生产服务器"
echo "=========================================="
echo ""

# 服务器配置（请根据实际情况修改）
SERVER_USER="your_username"
SERVER_HOST="your_server_ip_or_domain"
SERVER_PATH="/path/to/html.weburl.cloudns.be"

echo "⚠️  请先配置服务器信息："
echo "   编辑此脚本，修改以下变量："
echo "   - SERVER_USER: 服务器用户名"
echo "   - SERVER_HOST: 服务器地址"
echo "   - SERVER_PATH: 服务器目录路径"
echo ""
read -p "已配置好服务器信息？(y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消上传"
    exit 1
fi

# 检查部署包是否存在
if [ ! -f "production_deploy.tar.gz" ]; then
    echo "❌ 找不到 production_deploy.tar.gz"
    echo "   请先运行: ./prepare_production.sh"
    exit 1
fi

# 上传文件
echo "📤 上传文件到服务器..."
scp production_deploy.tar.gz ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/

if [ $? -eq 0 ]; then
    echo "✅ 上传成功！"
    echo ""
    echo "📝 下一步在服务器上执行："
    echo ""
    echo "ssh ${SERVER_USER}@${SERVER_HOST}"
    echo "cd ${SERVER_PATH}"
    echo "tar -xzf production_deploy.tar.gz"
    echo "nano .env  # 编辑数据库配置"
    echo "chmod 777 pub/"
    echo "chmod 600 .env"
    echo "curl https://html.weburl.cloudns.be/test_publish.php"
else
    echo "❌ 上传失败"
    exit 1
fi
