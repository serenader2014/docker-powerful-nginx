#!/usr/bin/env bash

docker run -d  --restart always \
    --name nginx-gen \
    --volumes-from nginx \
    -v $(pwd)/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    jwilder/docker-gen \
    -notify-sighup nginx -watch \
    -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
