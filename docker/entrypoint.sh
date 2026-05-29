#!/bin/bash
# HTML Code Editor - Docker Entrypoint
# 支持本地 Docker 数据库和外部第三方数据库

set -e

ENV_FILE="/var/www/html/.env"
CRON_FILE="/tmp/crontab.txt"

echo "==> HTML Code Editor Entrypoint Starting..."

# =============================================
# 生成 .env 配置文件
# =============================================
echo "==> Generating .env from environment variables..."

cat > "$ENV_FILE" << EOF
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-html_editor}
DB_USER=${DB_USER:-html_editor}
DB_PASS=${DB_PASS:-change_me_in_production}
DB_CHARSET=${DB_CHARSET:-utf8mb4}

ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-admin123admin123}

PUBLISH_API_KEY=${PUBLISH_API_KEY:-zheshimiyao112233}
HMAC_SECRET_KEY=${HMAC_SECRET_KEY:-zheshimiyao112233}

DEBUG=${DEBUG:-false}
CRON_SECRET_KEY=${CRON_SECRET_KEY:-expire_cron_2024_secret}
EOF

echo "==> .env generated"

chown www-data:www-data "$ENV_FILE"
chmod 640 "$ENV_FILE"

mkdir -p /var/www/html/pub
chown -R www-data:www-data /var/www/html/pub
chmod -R 755 /var/www/html/pub

# =============================================
# 等待数据库就绪 (TCP 层检查，不依赖认证)
# =============================================
DB_HOST_VAL="${DB_HOST:-db}"
DB_PORT_VAL="${DB_PORT:-3306}"

echo "==> Testing database connectivity: $DB_HOST_VAL:$DB_PORT_VAL"

MAX_RETRIES=30
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST_VAL/$DB_PORT_VAL" 2>/dev/null; then
        echo "==> Database port $DB_HOST_VAL:$DB_PORT_VAL is reachable!"
        break
    fi
    RETRY=$((RETRY + 1))
    echo "==> Waiting for database... ($RETRY/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY -ge $MAX_RETRIES ]; then
    echo "==> WARNING: Database not reachable after ${MAX_RETRIES}s, starting anyway..."
fi

# =============================================
# 配置 Cron 定时任务
# =============================================
echo "==> Setting up Cron jobs..."

cat > "$CRON_FILE" << CRON_EOF
*/5 * * * * /usr/local/bin/php /var/www/html/expire_cron.php >> /var/log/php/cron.log 2>&1
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