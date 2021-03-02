FROM alpine:edge

WORKDIR /var/www/html/

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor

# Installing bash
RUN apk add bash
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing PHP
RUN apk add --no-cache php \
    php-common \
    php-fpm \
    php-pdo \
    php-opcache \
    php-zip \
    php-phar \
    php-iconv \
    php-cli \
    php-curl \
    php-openssl \
    php-mbstring \
    php-tokenizer \
    php-fileinfo \
    php-json \
    php-xml \
    php-xmlwriter \
    php-simplexml \
    php-dom \
    php-pdo_mysql \
    php-pdo_sqlite \
    php-tokenizer \
    npm \

# Installing composer
    php7-pecl-redis
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY docker/supervisord.ini /etc/supervisor.d/supervisord.ini

# Configure php-fpm
RUN mkdir -p /run/php/
RUN touch /run/php/php7.4-fpm.pid
RUN touch /run/php/php7.4-fpm.sock

COPY docker/php-fpm.conf /etc/php7/php-fpm.conf

# Configure nginx
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf
COPY docker/fastcgi-php.conf /etc/nginx/fastcgi-php.conf

RUN mkdir -p /run/nginx/
RUN touch /run/nginx/nginx.pid

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Build process
COPY docker/pinchandzoom/ /var/www/html/
# RUN composer install --no-dev
#RUN php composer.json install
# RUN pwd
# RUN ls
RUN composer update -n
RUN php artisan key:generate --force
RUN php artisan migrate:fresh --force
RUN php artisan db:seed --force
RUN npm install
# RUN node -v
# RUN npm -v
RUN php artisan passport:install --force

# Container execution
EXPOSE 3000
CMD [ "php", "artisan", "serve", "--host=0.0.0.0", "--port=3000" ]
#CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
