# Criar imagem
docker-compose --env-file build-env-files/php-fpm/81/.env-mysql -f build-phpfpm.yml build

## Remover Label que causa confusão no front end do portainer
./docker-copyedit.py FROM localbuild/laravel-docker:8.1-alpine INTO localbuild/laravel-docker:8.1-alpine rm labels com.docker.compose.service and rm labels com.docker.compose.version and rm labels com.docker.compose.project
