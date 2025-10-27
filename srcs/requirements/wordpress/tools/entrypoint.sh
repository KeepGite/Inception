#!/bin/sh
set -e

if [ ! -f "wp-load.php" ]; then
  curl -sSL https://wordpress.org/latest.tar.gz | tar -xz --strip-components=1
  chown -R www-data:www-data /var/www/html
fi

sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf

if [ ! -f "wp-config.php" ]; then
  wp config create \
    --path=/var/www/html \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="${DB_HOST}" \
    --skip-check \
    --allow-root
fi

if ! wp core is-installed --allow-root; then
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root
fi

if wp user get admin1 --path=/var/www/html --allow-root > /dev/null 2>&1; then
    wp user delete admin1 --allow-root --path=/var/www/html --yes
fi


if ! wp user get "$WP_NORMAL_USER" --path=/var/www/html --allow-root > /dev/null 2>&1; then
    wp user create "$WP_NORMAL_USER" "$WP_NORMAL_EMAIL" \
        --role=editor \
        --user_pass=$WP_NORMAL_PASSWORD \
        --path=/var/www/html \
        --allow-root
fi

exec "$@"
