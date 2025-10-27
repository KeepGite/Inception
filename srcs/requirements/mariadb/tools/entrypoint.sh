#!/bin/bash
set -euo pipefail

DATA_DIR="/var/lib/mysql"
SOCKET_DIR="/var/run/mysqld"
SOCKET_PATH="${SOCKET_DIR}/mysqld.sock"

mkdir -p "${SOCKET_DIR}"
chown -R mysql:mysql "${SOCKET_DIR}"
chown -R mysql:mysql "${DATA_DIR}" || true

start_temp_server() {
    mariadbd \
        --skip-networking \
        --socket="${SOCKET_PATH}" \
        --datadir="${DATA_DIR}" \
        --user=mysql &
    TEMP_MARIADB_PID="$!"
}

wait_for_server() {
    until mariadb-admin --socket="${SOCKET_PATH}" --user=root ping >/dev/null 2>&1 \
        || mariadb-admin --socket="${SOCKET_PATH}" --user=root --password="${MYSQL_ROOT_PASSWORD}" ping >/dev/null 2>&1; do
        sleep 1
    done
}

stop_temp_server() {
    if ! mariadb-admin --socket="${SOCKET_PATH}" --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown >/dev/null 2>&1; then
        mariadb-admin --socket="${SOCKET_PATH}" --user=root shutdown >/dev/null 2>&1 || true
    fi
    wait "${TEMP_MARIADB_PID}"
}

if [ ! -d "${DATA_DIR}/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mariadb-install-db \
        --user=mysql \
        --datadir="${DATA_DIR}" \
        --auth-root-authentication-method=normal \
        --skip-test-db >/dev/null
fi

echo "Starting temporary MariaDB instance..."
start_temp_server
wait_for_server

ROOT_AUTH_ARGS=("--protocol=socket" "--socket=${SOCKET_PATH}" "--user=root")
if mariadb "${ROOT_AUTH_ARGS[@]}" --password="${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
    ROOT_AUTH_ARGS+=("--password=${MYSQL_ROOT_PASSWORD}")
fi

WP_CLIENT_HOST="${WORDPRESS_CLIENT_HOST:-%}"

cat <<SQL | mariadb "${ROOT_AUTH_ARGS[@]}"
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE OR REPLACE USER '${MYSQL_USER}'@'${WP_CLIENT_HOST}' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'${WP_CLIENT_HOST}';
CREATE OR REPLACE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

stop_temp_server

exec "$@"
