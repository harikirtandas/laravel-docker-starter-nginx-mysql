FROM php:8.4-fpm

RUN apt-get update && apt-get install -y \
    libzip-dev unzip git \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql bcmath zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ARG UID=1000
ARG GID=1000
RUN groupadd -g "$GID" app && useradd -u "$UID" -g app -m app

WORKDIR /var/www/html
USER app
