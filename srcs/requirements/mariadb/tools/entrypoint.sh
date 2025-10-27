#!/bin/bash
set -euo pipefail

DATA_DIR="/var/lib/mysql"
SOCKET_DIR="/var/run/mysqld"
SOCKET_PATH="${SOCKET_DIR}/mysqld.sock"

mkdir -p "${SOCKET_DIR}"
chown -R mysql:mysql "${SOCKET_DIR}"
chown -R mysql:mysql "${DATA_DIR}" || true

sql_escape_string() {
    local input="$1"
    printf "%s" "${input//"'"/"''"}"
}

sql_escape_identifier() {
    local input="$1"
    printf "%s" "${input//\`/\`\`}"
}

cleanup_temp_server() {
    if [ -n "${TEMP_MARIADB_PID:-}" ] && kill -0 "${TEMP_MARIADB_PID}" >/dev/null 2>&1; then
        stop_temp_server || true
    fi
}

trap cleanup_temp_server EXIT

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
    rm -f "${SOCKET_PATH}"
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

ESC_ROOT_PASSWORD="$(sql_escape_string "${MYSQL_ROOT_PASSWORD}")"
ESC_DB_NAME="$(sql_escape_identifier "${MYSQL_DATABASE}")"
ESC_WP_USER="$(sql_escape_string "${MYSQL_USER}")"
ESC_WP_PASSWORD="$(sql_escape_string "${MYSQL_PASSWORD}")"
ESC_CLIENT_HOST="$(sql_escape_string "${WP_CLIENT_HOST}")"

cat <<SQL | mariadb "${ROOT_AUTH_ARGS[@]}"
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ESC_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${ESC_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE OR REPLACE USER '${ESC_WP_USER}'@'${ESC_CLIENT_HOST}' IDENTIFIED BY '${ESC_WP_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${ESC_DB_NAME}\`.* TO '${ESC_WP_USER}'@'${ESC_CLIENT_HOST}';
CREATE OR REPLACE USER '${ESC_WP_USER}'@'%' IDENTIFIED BY '${ESC_WP_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${ESC_DB_NAME}\`.* TO '${ESC_WP_USER}'@'%';
FLUSH PRIVILEGES;
SQL

stop_temp_server

trap - EXIT

exec "$@"
