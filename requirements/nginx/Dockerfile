FROM alpine:3.18

RUN apk add --no-cache nginx openssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/docker-entrypoint.sh /usr/local/bin/

EXPOSE 443
ENTRYPOINT ["sh", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["nginx"]
