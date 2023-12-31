ARG DOCKER_IMAGE_VERSION
FROM php:${DOCKER_IMAGE_VERSION}

ARG PGSQL_DEP

# Install dependencies

RUN apk add --no-cache \
    freetype \
    libpng \
    libzip-dev \
    libjpeg-turbo \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    zip \
    git \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    curl \
    bash \
    tzdata ${PGSQL_DEP}

# Install dependencies nodejs
RUN apk add --no-cache \
    nodejs \
    yarn \
    npm

ARG PDO
ARG DOCKER_IMAGE_VERSION

# Install extensions
RUN docker-php-ext-install ${PDO} zip exif pcntl
COPY ./laravel/php-configure.sh /
RUN /php-configure.sh && rm -rf /php-configure.sh
RUN docker-php-ext-install gd

# build extensions
RUN apk add --no-cache pcre-dev $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev ${PHPIZE_DEPS} \
    && rm -rf /tmp/pear 

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ARG COMPOSER_VERSION
COPY ./laravel/composer.sh /
RUN /composer.sh && rm -rf /composer.sh

# Add user for laravel application
RUN addgroup --gid 1000 app && \
    adduser \
    --disabled-password \
    --gecos "" \
    --home /var/www/html \
    --ingroup app \
    --no-create-home \
    --uid 1000 \
    app && \
    addgroup app www-data

WORKDIR /root/

ARG LARAVEL_VERSION
RUN rm -rf /var/www/html \
    && curl -SLJ https://github.com/laravel/laravel/archive/v${LARAVEL_VERSION}.tar.gz  | tar -zxC /root/ \
    && mv /root/laravel-${LARAVEL_VERSION} /var/www/html \
    && chown -R www-data:www-data /var/www \
    && rm -rf /root/laravel-${LARAVEL_VERSION}

WORKDIR /var/www/html/

ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


ENV LANG pt_BR.UTF-8
ENV LANGUAGE pt_BR:pt
ENV LC_ALL pt_BR.UTF-8

ARG DB

COPY ./laravel/docker-entrypoint-${DB}.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

COPY ./laravel/wait-${DB}.php /usr/local/bin/

# Set working directory
VOLUME /var/www/html

# Change current user to www
USER app 

CMD ["php-fpm"]