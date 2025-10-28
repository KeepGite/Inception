#!/bin/bash

mkdir -p /var/lib/mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld

if [ ! -f "/var/lib/mysql/.initialized" ]; then
    echo "Initialisation de la base de données..."
    
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    fi

    mysqld_safe --datadir=/var/lib/mysql &
    pid="$!"

    echo "Attente du démarrage de MariaDB..."
    sleep 5

    mysql << EOF
DELETE FROM mysql.user WHERE User='';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    echo "Stop temp MariaDB..."
    mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown
    wait "$pid"
    
    touch /var/lib/mysql/.initialized
    echo "Init finish !"
fi

echo "Démarrage de MariaDB..."
mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0