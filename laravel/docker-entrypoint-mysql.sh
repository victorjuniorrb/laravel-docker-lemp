#!/bin/bash
set -euo pipefail
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

build_env_file(){
    : "${LARAVEL_DB_HOST:=mysql}"
    : "${MYSQL_USER:=app}"
    : "${MYSQL_PASSWORD:=password}"
    : "${MYSQL_DATABASE:=laravel}"
    : "${APP_NAME:=Laravel}"
    : "${APP_ENV:=local}"
    : "${APP_DEBUG:=true}"
    : "${MAIL_HOST:=}"
    : "${MAIL_PORT:=}"
    : "${MAIL_USERNAME:=}"
    : "${MAIL_PASSWORD:=}"
    : "${MAIL_ENCRYPTION:=}"
    : "${MAIL_FROM_ADDRESS:=}"
    : "${MAIL_FROM_NAME:=}"

    cat << EOF >> /var/www/html/.env
APP_NAME=$APP_NAME
APP_ENV=${APP_ENV}
APP_KEY=
APP_DEBUG=${APP_DEBUG}
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=$LARAVEL_DB_HOST
DB_PORT=3306
DB_DATABASE=$MYSQL_DATABASE
DB_USERNAME=$MYSQL_USER
DB_PASSWORD=$MYSQL_PASSWORD

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=$MAIL_HOST
MAIL_PORT=$MAIL_PORT
MAIL_USERNAME=$MAIL_USERNAME
MAIL_PASSWORD=$MAIL_PASSWORD
MAIL_ENCRYPTION=$MAIL_ENCRYPTION
MAIL_FROM_ADDRESS=$MAIL_FROM_ADDRESS
MAIL_FROM_NAME=$MAIL_FROM_NAME

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

MIX_PUSHER_APP_KEY=""
MIX_PUSHER_APP_CLUSTER=""
EOF
}

ROLE=${CONTAINER_ROLE:-app}
QUEUE_NAME=${QUEUE_NAME:-default}

if [ "$ROLE" = "queue" ]; then
    echo "Running the queue..."
    php artisan queue:work database --queue=$QUEUE_NAME --verbose --tries=3
elif [ "$ROLE" = "scheduler" ]; then
    echo "Running the scheduler..."
    while [ true ]
    do
      php artisan schedule:run --verbose --no-interaction &
      sleep 60
    done
elif [ "$ROLE" = "app" ]; then
    if [ "$1" == php-fpm ]  || [ "$1" == php ]; then
        echo "Exposing Laravel..."
        file_env 'FORCE_MIGRATE'
        file_env 'FORCE_COMPOSER_UPDATE'
        file_env 'APP_ENV'
        if [[ ! -d /var/www/html/vendor ]]; then
            if [[ "$APP_ENV" == "production" ]]; then
                composer install --optimize-autoloader --no-dev
                echo "Composer install production"
            else
                composer install
                echo "Composer install dev"
            fi
        fi
        if [[ ! -d /var/www/html/node_modules ]]; then
            npm install
            echo "npm install"
        fi
        if [ -z "$FORCE_COMPOSER_UPDATE" ]; then
            echo "Skipping composer update"
        else
            composer update
            echo "Composer update"
        fi

        FILE=/var/www/html/.env
        if ! [ -f "$FILE" ]; then
            build_env_file
            php artisan optimize:clear
            php artisan key:generate
            php artisan config:cache
            npm run build
            php -f /usr/local/bin/wait-mysql.php
        fi
        if [ -z "$FORCE_MIGRATE" ]; then
            echo "DB initialization skipped"
        else
            php artisan migrate --force
        fi
    fi
fi

exec "$@"
