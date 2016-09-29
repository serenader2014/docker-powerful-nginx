#!/usr/bin/env bash

docker run --name nginx --restart always -d -p 80:80 -p 443:443 \
    -v /etc/nginx/conf.d:/etc/nginx/conf.d  \
    -v /etc/nginx/vhost.d:/etc/nginx/vhost.d \
    -v /etc/nginx/html:/usr/share/nginx/html \
    -v /etc/nginx/ssl:/etc/nginx/certs:ro \
    -v /etc/nginx/htpasswd:/etc/nginx/htpasswd \
    -v /etc/nginx/verynginx:/opt/verynginx/verynginx/configs:rw \
    -v /etc/nginx/www:/etc/nginx/www:rw \
    serenader/docker-nginx-http2-verynginx
