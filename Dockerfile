FROM php:8.2-cli AS base

WORKDIR /app

RUN apt update && \
    apt install -y unzip git libzip-dev && \
    docker-php-ext-install zip
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json ./

#Dependencias de no desarrollo
RUN composer install --no-dev

# docker buildx build -t calculadora:base --target base .

# Multi Stage
FROM base AS dev

RUN pecl install xdebug && docker-php-ext-enable xdebug

COPY ./docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

COPY . .

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]


# Test
FROM base AS test 

RUN composer require --dev phpunit/phpunit

COPY . .

# ./vendor/bin/phpunit --textdox tests
#CMD es el ultimo comando que se va a poner
CMD ["./vendor/bin/phpunit", "--testdox", "tests"]

#Produccion
FROM base AS prod

COPY . .

RUN composer install --no-dev --optimize-autoloader

#Aqui se pone todo lo que no es necesario subir, es decir lo no necesario
RUN rm -rf docker/ tests/ 

EXPOSE 80

CMD ["php", "-S", "0.0.0.0:80", "-t", "public"]

#Aqui ya se pone la version en el docker buildx



