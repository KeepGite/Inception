ARG DEBIAN_TAG=bookworm-slim
FROM debian:${DEBIAN_TAG}

RUN apt-get update && apt-get install -y iputils-ping

RUN apt-get update && apt-get install -y mariadb-server && rm -rf /var/lib/apt/lists/*

RUN        mkdir -p /var/run/mysqld && \
            chown -R mysql:mysql /var/run/mysqld

COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT    ["/usr/local/bin/entrypoint.sh"]

USER mysql

CMD    ["mariadbd"]