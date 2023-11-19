FROM php:5.6.40-apache

MAINTAINER cronv <mister.swim@yandex.ru>

# deb fast (http)
# Installing necessary packages and Apache
RUN echo "deb http://archive.debian.org/debian/ stretch main non-free contrib" > /etc/apt/sources.list \
    && echo "deb-src http://archive.debian.org/debian/ stretch main non-free contrib" >> /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian-archive/debian-security stretch/updates main" >> /etc/apt/sources.list \
    && echo "deb-src http://archive.debian.org/debian-archive/debian-security stretch/updates main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev libmemcached-dev libbz2-dev \
        libssl-dev librabbitmq-dev libxml2-dev libxslt1.1 libxslt1-dev libzip-dev libpq-dev \
        libssh2-1-dev libtidy-dev unzip libc-client-dev libkrb5-dev libmcrypt-dev git subversion mc nano iputils-ping \
    && a2enmod rewrite \
    && docker-php-ext-configure zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && pecl channel-update pecl.php.net \
    && printf "\n" | pecl install memcached-2.2.0 \
    && printf "\n" | pecl install memcache-2.2.7 \
    && printf "\n" | pecl install redis-4.3.0 \
    && printf "\n" | pecl install mongo \
    && printf "\n" | pecl install mongodb-1.7.5 \
    && printf "\n" | pecl install amqp-1.11.0 \
    && printf "\n" | pecl install ssh2-0.13 \
    && printf "\n" | pecl install rar \
    && printf "\n" | pecl install dbase-5.1.1 \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable memcached memcache redis mongo mongodb amqp ssh2 rar dbase \
    && docker-php-ext-install bcmath bz2 calendar exif opcache pdo_mysql mysql mysqli pdo_mysql pgsql pdo_pgsql intl zip soap gd xsl pcntl sockets imap tidy mcrypt \
    && a2enmod ssl \
    && chmod 777 /var/log

# Build xdebug manually to avoid a debian compiler bug https://github.com/docker-library/php/issues/133
# Method taked from https://github.com/my127/docker-php/blob/master/installer/stretch/extensions/xdebug.sh
ENV XDEBUG_PACKAGE="xdebug-2.5.5"
RUN cd /usr/src \
    && curl --insecure "https://xdebug.org/files/${XDEBUG_PACKAGE}.tgz" -o "${XDEBUG_PACKAGE}.tgz" \
    && echo "72108bf2bc514ee7198e10466a0fedcac3df9bbc5bd26ce2ec2dafab990bf1a4" "${XDEBUG_PACKAGE}.tgz" | sha256sum --check \
    && tar -xzvf "${XDEBUG_PACKAGE}.tgz" \
    && cd "${XDEBUG_PACKAGE}" \
    && phpize \
    && ./configure --enable-xdebug \
    && make clean \
    && sed -i 's/-O2/-O0/g' Makefile \
    && make \
    && make test \
    && make install \
    && cd .. \
    && rm -r "${XDEBUG_PACKAGE}" "${XDEBUG_PACKAGE}.tgz" \
    && docker-php-ext-enable xdebug \
    && rm -rf /usr/src/*

# Installing Composer using curl and PHP
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
