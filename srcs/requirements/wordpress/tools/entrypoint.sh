#!/bin/sh
set -e

mkdir -p /run/php && chown www-data:www-data /run/php

sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/8.1/fpm/pool.d/www.conf

if [ ! -f /var/www/html/index.php ]; then
    wp core download --path=/var/www/html --version=6.8 --allow-root
fi

if [ ! -f /var/www/html/wp-config.php ]; then
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOST" \
        --path=/var/www/html \
        --allow-root

fi

if ! wp core is-installed --path=/var/www/html --allow-root; then
    wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path=/var/www/html \
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


if ! wp theme install astra --path=/var/www/html --allow-root; then
    wp theme install astra --activate --allow-root
fi

exec "$@"