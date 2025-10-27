ARG DEBIAN_TAG=bookworm-slim
FROM debian:${DEBIAN_TAG}

RUN        apt-get update && apt-get install -y iputils-ping

RUN     apt    update && \
        apt    install -y mariadb-server mariadb-client && \
        rm    -rf    /var/lib/apt/lists/*

RUN        mkdir -p /var/run/mysqld && \
            chown -R mysql:mysql /var/run/mysqld

COPY    my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf


COPY    docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN        chmod +x /usr/local/bin/docker-entrypoint.sh


ENTRYPOINT    ["/usr/local/bin/docker-entrypoint.sh"]

USER mysql

CMD    ["mariadbd"]