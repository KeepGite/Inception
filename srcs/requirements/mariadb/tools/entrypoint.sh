#!/bin/bash
set -e

if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    mysqld_safe --user=mysql --skip-grant-tables &
    sleep 5

    WP_CLIENT_HOSTS="${WORDPRESS_CLIENT_HOSTS:-${WORDPRESS_CLIENT_HOST:-wordpress.%}}"
    WP_CLIENT_HOSTS+=" ,%"

    IFS=',' read -ra RAW_HOSTS <<< "$WP_CLIENT_HOSTS"
    declare -A SEEN_HOSTS=()

    {
        echo "FLUSH PRIVILEGES;"
        echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
        echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;"
    } > /tmp/init.sql

    for raw_host in "${RAW_HOSTS[@]}"; do
        host="$(echo "$raw_host" | xargs)"
        if [ -z "$host" ] || [ -n "${SEEN_HOSTS[$host]}" ]; then
            continue
        fi
        SEEN_HOSTS[$host]=1
        {
            echo "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'$host' IDENTIFIED BY '$MYSQL_PASSWORD';"
            echo "GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'$host';"
        } >> /tmp/init.sql
    done

    echo "FLUSH PRIVILEGES;" >> /tmp/init.sql

    mariadb -u root < /tmp/init.sql

    rm /tmp/init.sql
fi

if pgrep mysqld; then
    mysqladmin shutdown
fi

exec "$@"
