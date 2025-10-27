#!/bin/sh
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
  mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
  mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
  pid="$!"

  for i in 1 2 3 4 5 6 7 8 9 10; do
    mysqladmin ping >/dev/null 2>&1 && break
    sleep 1
  done

  mysql -uroot << SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PW}';
    FLUSH PRIVILEGES;
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${USER_PW}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
SQL

  mysqladmin -uroot -p"${ROOT_PW}" shutdown
  wait "${pid}"
fi

exec "$@"
