#!/bin/sh
set -eu

PHP_POOL_DIR="/etc/php/${PHP_VERSION}/fpm/pool.d"
POOL_CONF="${PHP_POOL_DIR}/www.conf"
WP_PATH="/var/www/html"
DB_HOST_VALUE="${MYSQL_HOST:-mariadb}"
DB_PORT="${MYSQL_PORT:-3306}"
DB_HOST="${DB_HOST_VALUE}:${DB_PORT}"

mkdir -p /run/php
chown www-data:www-data /run/php

if [ -f "${POOL_CONF}" ]; then
    sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' "${POOL_CONF}"
fi

until mariadb -h "${DB_HOST_VALUE}" -P "${DB_PORT}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "Waiting for MariaDB to be ready..."
    sleep 2
done

if [ ! -f "${WP_PATH}/wp-load.php" ]; then
    wp core download --path="${WP_PATH}" --allow-root
fi

if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --path="${WP_PATH}" \
        --allow-root \
        --skip-check
else
    wp config set DB_NAME "${MYSQL_DATABASE}" --type=constant --path="${WP_PATH}" --allow-root --raw
    wp config set DB_USER "${MYSQL_USER}" --type=constant --path="${WP_PATH}" --allow-root --raw
    wp config set DB_PASSWORD "${MYSQL_PASSWORD}" --type=constant --path="${WP_PATH}" --allow-root --raw
    wp config set DB_HOST "${DB_HOST}" --type=constant --path="${WP_PATH}" --allow-root --raw
fi

if ! wp core is-installed --path="${WP_PATH}" --allow-root >/dev/null 2>&1; then
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --path="${WP_PATH}" \
        --allow-root
fi

if ! wp user get "${WP_NORMAL_USER}" --path="${WP_PATH}" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_NORMAL_USER}" "${WP_NORMAL_EMAIL}" \
        --role=editor \
        --user_pass="${WP_NORMAL_PASSWORD}" \
        --path="${WP_PATH}" \
        --allow-root
fi

if ! wp theme is-installed astra --path="${WP_PATH}" --allow-root >/dev/null 2>&1; then
    wp theme install astra --allow-root --path="${WP_PATH}"
fi

if ! wp theme is-active astra --path="${WP_PATH}" --allow-root >/dev/null 2>&1; then
    wp theme activate astra --allow-root --path="${WP_PATH}"
fi

chown -R www-data:www-data "${WP_PATH}"

exec "$@"
