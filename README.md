# Docker Powerful Nginx

### 它能干什么？

本项目旨在为开发人员快速搭建配置好的一套 Nginx 环境。该环境支持 HTTP2 ，并且支持 Let's Encrypt，自动签发 SSL 证书，并且自动更新证书有效期。该环境还配置了 VeryNginx ，极大地简化了 Nginx 的配置。

### 如何使用

- 安装 docker
- 确保当前用户有权限执行 `docker ps`，如果没有的话需要将当前用户添加到 `docker` 用户组：`usermod -aG docker $(whoami)`
- clone 该项目
- 在该项目下面运行 `./run.sh`
- 使用 `docker logs` 查看各个容器是否正常运行，如果正常的话即可开始部署其他容器


### 运行其他程序容器

如果运行的容器需要配置 Virtual Host 时，则在运行 docker 命令时，添加一个 `VIRTUAL_HOST` 的环境变量，并且确保有 expose 端口出来，如：

```bash
docker run --expose 2368 -d --name ghost --restart always -v /var/lib/ghost:/var/lib/ghost -e "VIRTUAL_HOST=blog.example.com" ghost
```

此时当运行这个 Ghost 容器之后，nginx-gen 容器会自动生成一个 nginx 配置文件，并且会监听 `blog.example.com` 这个域名，并且把请求代理到 Ghost 这个容器所 expose 出来的端口中，这时候就完成了 virtual host 的配置，无需再编写 nginx 配置。

同样的道理，如果运行的容器不仅需要配 virtual host ，而且还要自动签发 SSL 证书，那么则需要再添加多两个环境变量 `LETSENCRYPT_HOST` 和 `LETSENCRYPT_EMAIL` :

```bash
docker run --expose 2368 -d --name ghost --restart always -v /var/lib/ghost:/var/lib/ghost -e "VIRTUAL_HOST=blog.example.com" -e "LETSENCRYPT_HOST=blog.example.com" -e "LETSENCRYPT_EMAIL=xyslive@gmail.com" ghost
```

通常来说，`VIRTUAL_HOST` 跟 `LETSENCRYPT_HOST` 应该是同一个域名。

运行完该容器后，不出意外的话，nginx-letsencrypt 容器则会在后台自动调用 Let's Encrypt 的 API 自动签发证书，当签发成功时会再触发 nginx-gen 容器生成相应的 HTTPS 的 nginx 配置文件。如果一切成功的话，那么此时你访问 `http://blog.example.com` 就会自动跳转到 `https://blog.example.com` 这个域名下了。


#### DEMO

##### Wordpress

```
docker run --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql
docker run --name wordpress --link mysql:mysql -d -e "VIRTUAL_HOST=wp.example.com" -e "LETSENCRYPT_HOST=wp.example.com" -e "LETSENCRYPT_EMAIL=xyslive@gmail.com" --expose 80 wordpress
```

##### Ghost

```
docker run --expose 2368 -d --name ghost --restart always -v /var/lib/ghost:/var/lib/ghost -e "VIRTUAL_HOST=blog.example.com" -e "LETSENCRYPT_HOST=blog.example.com" -e "LETSENCRYPT_EMAIL=xyslive@gmail.com" ghost
```

### 证书签发不成功

请先确认域名有解析到该服务器上，并且确保可以正常访问 http:// 协议。上面的例子中，如果你所配置的 Ghost 的配置文件里面，一开始就把 url 配置成 https:// 协议的话，那么会导致 Ghost 会将所有 http 请求 301 到 https 请求上，因此没办法通过 Let's Encrypt 的验证。

nginx-letsencrypt 容器签发证书的原理是：

- 运行该容器，并且在 nginx 容器的 `/usr/share/nginx/html` 文件夹赋予读写权限，并且写入一段 nginx 配置

```nginx
location /.well-known/acme-challenge/ {
    allow all;
    root /usr/share/nginx/html;
    try_files $uri =404;
    break;
}
```

- 监听是否有容器启动，并且是否有 `LETSENCRYPT_HOST` 和 `LETSENCRYPT_EMAIL` 两个环境变量
- 收到容器启动的命令，开始调用 Let's Encrypt 的 API，此时 Let's Encrypt 的 API 返回一个验证文件，nginx-letsencrypt 则把该文件写入 nginx 的 `/usr/share/nginx/html` 文件夹中，当做静态文件托管
- Let's Encrypt 的 API 开始验证域名所有权，此时会访问 `http://blog.example.com/.well-known/acme-challenge/${token}` ，`${token}` 则是刚刚保存的验证文件的文件名
- nginx 接收到请求，开始到 `/usr/share/nginx/html` 查找是否有所找的文件，有的话则返回该文件，没有的话返回 404 
- 当 nginx 返回的文件被 Let's Encrypt 标识为验证成功时，则表示域名验证成功，开始发放证书
- nginx-letsencrypt 容器接收到证书后，触发 nginx-gen 生成相关的 https 的 nginx 配置文件
- 至此证书签发成功，并且 nginx 的 https 配置也成功了

### 添加额外的 nginx 配置

### VeryNginx 的配置
