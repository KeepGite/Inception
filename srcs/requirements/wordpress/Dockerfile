ARG DEBIAN_TAG=bookworm-slim
FROM debian:${DEBIAN_TAG}

RUN apt-get update && apt-get install -y iputils-ping

RUN apt-get update && apt-get install -y \
    php-fpm php-mysql php-cli curl tar ca-certificates less \
 && rm -rf /var/lib/apt/lists/*

RUN curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp

RUN     apt-get update && apt-get install -y php8.2 \
        php8.2-fpm \
        php8.2-cli \
        php8.2-mysql \
        mariadb-client

COPY conf/php-fpm.conf /etc/php/8.1/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm", "-F"]
