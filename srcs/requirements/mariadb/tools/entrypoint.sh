#!/bin/bash
set -euo pipefail

DATA_DIR="/var/lib/mysql"
SOCKET_DIR="/var/run/mysqld"
SOCKET_PATH="${SOCKET_DIR}/mysqld.sock"

mkdir -p "${SOCKET_DIR}"
chown -R mysql:mysql "${SOCKET_DIR}"
chown -R mysql:mysql "${DATA_DIR}" || true

if [ ! -d "${DATA_DIR}/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mariadb-install-db \
        --user=mysql \
        --datadir="${DATA_DIR}" \
        --auth-root-authentication-method=normal \
        --skip-test-db >/dev/null

    echo "Starting temporary MariaDB instance..."
    mariadbd \
        --skip-networking \
        --socket="${SOCKET_PATH}" \
        --datadir="${DATA_DIR}" \
        --user=mysql &
    pid="$!"

    until mariadb-admin --socket="${SOCKET_PATH}" --user=root ping >/dev/null 2>&1; do
        sleep 1
    done

    WP_CLIENT_HOST="${WORDPRESS_CLIENT_HOST:-%}"

    cat <<SQL | mariadb --protocol=socket --socket="${SOCKET_PATH}" --user=root
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'${WP_CLIENT_HOST}' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'${WP_CLIENT_HOST}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

    mariadb-admin \
        --socket="${SOCKET_PATH}" \
        --user=root \
        --password="${MYSQL_ROOT_PASSWORD}" \
        shutdown
    wait "${pid}"
fi

exec "$@"
