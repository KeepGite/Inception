ARG DEBIAN_TAG=bookworm-slim
FROM debian:${DEBIAN_TAG}

ARG PHP_VERSION=8.2
ENV PHP_VERSION=${PHP_VERSION}

RUN apt-get update \
    && apt-get install -y curl ca-certificates tar less mariadb-client \
       php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-mysql php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/local/sbin/php-fpm

COPY conf/php-fpm.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm", "-F"]
