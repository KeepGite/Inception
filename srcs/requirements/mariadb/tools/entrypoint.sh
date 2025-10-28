#!/bin/bash

# Création des répertoires nécessaires
mkdir -p /var/lib/mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Initialisation de la base de données si elle n'existe pas
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initialisation de la base de données..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Démarrage temporaire de MariaDB pour l'initialisation
mysqld_safe --datadir=/var/lib/mysql &
pid="$!"

sleep 3

    mysql << EOF
-- Suppression des utilisateurs par défaut
DELETE FROM mysql.user WHERE User='';


CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;



CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';


FLUSH PRIVILEGES;
EOF

echo "Arret temporaire..."
mysqladmin shutdown
wait "$pid"
fi

echo "Démarrage de MariaDB..."
# Démarrage de MariaDB en mode normal
mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0