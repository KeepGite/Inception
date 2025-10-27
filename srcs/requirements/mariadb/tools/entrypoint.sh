#!/bin/bash
set -e

if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    mysqld_safe --user=mysql --skip-grant-tables &
        sleep 5

cat > /tmp/init.sql <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
CREATE DATABASE IF NOT EXISTS `$DB_NAME`;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON `$DB_NAME`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF

    mariadb -u root < /tmp/init.sql

    rm /tmp/init.sql
fi

if pgrep mysqld; then
    mysqladmin shutdown
fi

exec "$@"
