set -e

DB_PASS="$(${DB_PASSWORD})"
ADMIN_PASS="$(${WP_ADMIN_PASSWORD})"

if [ ! -f "wp-load.php" ]; then
  curl -sSL https://wordpress.org/latest.tar.gz | tar -xz --strip-components=1
  chown -R www-data:www-data /var/www/html
fi

if [ ! -f "wp-config.php" ]; then
  wp config create \
    --path=/var/www/html \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
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

exec "$@"
