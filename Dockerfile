FROM php:8.2-apache

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_PROCESS_TIMEOUT 0
ENV TZ Asia/Tokyo

WORKDIR /var/www/
COPY . .


RUN apt update  && \
    apt install -y vim zip libpq-dev && \
    curl -sS https://getcomposer.org/installer | php  && \
    mv ./composer.phar /usr/local/bin/composer && \
    docker-php-ext-install pgsql pdo_pgsql

# Start and enable ssh
RUN apt-get update \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd
COPY sshd_config /etc/ssh/

EXPOSE 8000 2222


RUN a2enmod rewrite headers

COPY ./docker/install/files/apache/default.conf /etc/apache2/sites-enabled/000-default.conf

RUN composer install --no-dev \
 && chmod 777 -R storage \
 && chmod 777 -R bootstrap/cache

RUN chmod 744 ./startup.sh

ENTRYPOINT ["./startup.sh"]

