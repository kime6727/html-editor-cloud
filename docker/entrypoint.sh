#!/bin/bash
# HTML Code Editor - Docker Entrypoint
# 从环境变量生成 .env 配置，设置 Cron，启动服务

set -e

ENV_FILE="/var/www/html/.env"
CRON_FILE="/tmp/crontab.txt"

echo "==> HTML Code Editor Entrypoint Starting..."

# =============================================
# 修复 Docker DNS 解析
# =============================================
echo "==> Configuring Docker DNS..."
cat > /etc/resolv.conf << 'DNS_EOF'
nameserver 127.0.0.11
options ndots:0
DNS_EOF
echo "==> /etc/resolv.conf updated"

echo "==> Testing db resolution..."
sleep 2
if getent hosts db > /dev/null 2>&1; then
    DB_IP=$(getent hosts db | awk '{print $1}')
    echo "==> db resolved to: $DB_IP"
else
    echo "==> WARNING: db not resolving yet, will retry..."
    for i in $(seq 1 10); do
        sleep 3
        if getent hosts db > /dev/null 2>&1; then
            echo "==> db resolved on retry $i: $(getent hosts db | awk '{print $1}')"
            break
        fi
    done
fi

# =============================================
# 生成 .env 配置文件
# =============================================
echo "==> Generating .env from environment variables..."

cat > "$ENV_FILE" << EOF
# HTML Code Editor - 环境配置（Docker 自动生成）
# =============================================

# 数据库配置
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-html_editor}
DB_USER=${DB_USER:-html_editor}
DB_PASS=${DB_PASS:-change_me_in_production}
DB_CHARSET=${DB_CHARSET:-utf8mb4}

# 管理员账号
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-admin123admin123}

# API密钥
PUBLISH_API_KEY=${PUBLISH_API_KEY:-zheshimiyao112233}
HMAC_SECRET_KEY=${HMAC_SECRET_KEY:-zheshimiyao112233}

# 调试模式
DEBUG=${DEBUG:-false}

# Cron任务密钥
CRON_SECRET_KEY=${CRON_SECRET_KEY:-expire_cron_2024_secret}
EOF

echo "==> .env generated successfully"

# =============================================
# 设置文件权限
# =============================================
chown www-data:www-data "$ENV_FILE"
chmod 640 "$ENV_FILE"

# 确保 pub 目录存在且有正确权限
mkdir -p /var/www/html/pub
chown -R www-data:www-data /var/www/html/pub
chmod -R 755 /var/www/html/pub

# =============================================
# 等待 MySQL 就绪
# =============================================
echo "==> Waiting for MySQL to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while ! mysqladmin ping -h "${DB_HOST:-db}" -u "${DB_USER:-html_editor}" -p"${DB_PASS:-change_me_in_production}" --silent 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "==> WARNING: MySQL not ready after $MAX_RETRIES attempts, starting anyway..."
        break
    fi
    echo "==> MySQL not ready yet (attempt $RETRY_COUNT/$MAX_RETRIES)..."
    sleep 2
done

if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "==> MySQL is ready!"
    
    # 初始化数据库（幂等操作）
    echo "==> Running database initialization..."
    if [ -f /var/www/html/database/init_mysql84.sql ]; then
        mysql -h "${DB_HOST:-db}" -u "${DB_USER:-html_editor}" -p"${DB_PASS:-change_me_in_production}" \
            "${DB_NAME:-html_editor}" < /var/www/html/database/init_mysql84.sql 2>/dev/null || true
        echo "==> Database initialization completed"
    fi
fi

# =============================================
# 配置 Cron 定时任务
# =============================================
echo "==> Setting up Cron jobs..."

cat > "$CRON_FILE" << CRON_EOF
# 每 5 分钟运行过期检查
*/5 * * * * /usr/local/bin/php /var/www/html/expire_cron.php >> /var/log/php/cron.log 2>&1

# 每天凌晨 3 点清理旧日志
0 3 * * * find /var/log/nginx -name "*.log" -mtime +30 -delete 2>/dev/null
0 3 * * * find /var/log/php -name "*.log" -mtime +30 -delete 2>/dev/null
CRON_EOF

crontab -u root "$CRON_FILE"
echo "==> Cron jobs configured"

# =============================================
# 启动服务
# =============================================
echo "==> Starting services via Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf