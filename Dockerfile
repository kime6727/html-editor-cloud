# HTML Code Editor - Dockerfile
# PHP 8.3 + Nginx + Supervisor 单容器部署
FROM php:8.3-fpm-alpine

LABEL description="HTML Code Editor - Cloud Publishing Backend"

# 安装系统依赖 + PHP扩展编译依赖
RUN apk add --no-cache \
    nginx \
    supervisor \
    mariadb-client \
    dcron \
    bash \
    curl \
    tzdata \
    oniguruma-dev \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 安装 PHP 扩展
RUN docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    mbstring

# 配置 PHP-FPM
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && sed -i 's/^listen = .*/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/^;clear_env = no/clear_env = no/' /usr/local/etc/php-fpm.d/www.conf \
    && echo 'php_admin_value[upload_max_filesize] = 50M' >> /usr/local/etc/php-fpm.d/www.conf \
    && echo 'php_admin_value[post_max_size] = 55M' >> /usr/local/etc/php-fpm.d/www.conf \
    && echo 'php_admin_value[max_execution_time] = 120' >> /usr/local/etc/php-fpm.d/www.conf

# 配置 Nginx
RUN mkdir -p /run/nginx /var/log/nginx /var/log/php \
    && chown -R www-data:www-data /var/log/nginx /var/log/php

# 复制应用代码
COPY deploy_package/ /var/www/html/

# 复制 Nginx 站点配置
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

# 复制 Supervisor 配置
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 复制启动脚本
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 创建 pub 目录并设置权限
RUN mkdir -p /var/www/html/pub \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/pub

# 清理
RUN rm -f /etc/nginx/http.d/default.conf 2>/dev/null || true

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]