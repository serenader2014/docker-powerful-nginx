docker run --name nginx --restart always -d -p 80:80 -p 443:443 \
    -v /etc/nginx/conf.d:/etc/nginx/conf.d  \
    -v /etc/nginx/vhost.d:/etc/nginx/vhost.d \
    -v /etc/nginx/html:/usr/share/nginx/html \
    -v /etc/nginx/ssl:/etc/nginx/certs:ro \
    -v /etc/nginx/htpasswd:/etc/nginx/htpasswd \
    -v /etc/nginx/verynginx:/opt/verynginx/verynginx/configs:rw \
    -v /etc/nginx/www:/etc/nginx/www:rw \
    serenader/docker-nginx-http2-verynginx

docker run -d  --restart always \
    --name nginx-gen \
    --volumes-from nginx \
    -v $(pwd)/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    jwilder/docker-gen \
    -notify-sighup nginx -watch \
    -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

docker run -d --restart always \
    --name nginx-letsencrypt \
    -e "NGINX_DOCKER_GEN_CONTAINER=nginx-gen" \
    --volumes-from nginx \
    -v /etc/nginx/ssl:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion
