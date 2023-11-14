#!/bin/sh
# build e pull images php-fpm and php-alpine
#
# sabores de imagem base
# php-fpm | alpine

# sabores de versão php
# 73 | 74 | 8 | 81

# sabores de banco de dados
# mysql | pgsql

REGISTRY="registry.cett.org.br"

# loop para imagens
for i in alpine php-fpm; do
    # loop para php
    for p in 74 81; do
        # loop para Banco de Dados
        for d in mysql; do
            # build image
            docker compose --env-file build-env-files/$i/$p/.env-$d -f build-$i.yml build
            
            # Remover Label que causa confusão no front end do portainer
            ./docker-copyedit.py FROM localbuild/laravel-docker:$i-$p-$d \
                INTO localbuild/laravel-docker:$i-$p-$d \
                rm labels com.docker.compose.service and \
                rm labels com.docker.compose.version and \
                rm labels com.docker.compose.project

            # Trocar TAG para repositório REGISTRY
            docker tag localbuild/laravel-docker:$i-$p-$d $REGISTRY/laravel-docker:$i-$p-$d
            
            # push para repositório
            docker push $REGISTRY/laravel-docker:$i-$p-$d

            # Remover imagen localbuild
            docker image rm localbuild/laravel-docker:$i-$p-$d
        done
    done
done