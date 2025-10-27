#!/bin/bash
set -e

if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    mysqld_safe --user=mysql --skip-grant-tables &
    sleep 5

    raw_client_hosts="${WORDPRESS_CLIENT_HOSTS:-${WORDPRESS_CLIENT_HOST:-}}"
    IFS=',' read -ra potential_hosts <<< "$raw_client_hosts"

    declare -a grant_hosts=()

    add_host() {
        local candidate="$1"
        local existing

        if [ -z "$candidate" ]; then
            return
        fi

        for existing in "${grant_hosts[@]}"; do
            if [ "$existing" = "$candidate" ]; then
                return
            fi
        done

        grant_hosts+=("$candidate")
    }

    if [ "${#potential_hosts[@]}" -eq 0 ] || { [ "${#potential_hosts[@]}" -eq 1 ] && [ -z "${potential_hosts[0]}" ]; }; then
        add_host "wordpress.%"
    else
        for raw_host in "${potential_hosts[@]}"; do
            add_host "$(echo "$raw_host" | xargs)"
        done
    fi

    add_host "%"

    {
        echo "FLUSH PRIVILEGES;"
        echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
        echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;"

        for host in "${grant_hosts[@]}"; do
            echo "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'$host' IDENTIFIED BY '$MYSQL_PASSWORD';"
            echo "GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'$host';"
        done

        echo "FLUSH PRIVILEGES;"
    } > /tmp/init.sql

    mariadb -u root < /tmp/init.sql

    rm /tmp/init.sql
fi

if pgrep mysqld > /dev/null; then
    mysqladmin --user=root --password="$MYSQL_ROOT_PASSWORD" shutdown
fi

exec "$@"
