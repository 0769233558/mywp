FROM alpine:3.18

RUN addgroup -S mysql
RUN adduser --disabled-password --ingroup mysql mysql

RUN apk add --no-cache mariadb mariadb-client su-exec

COPY tools/docker-entrypoint.sh /usr/local/bin/

EXPOSE 3306
ENTRYPOINT ["sh", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["mariadbd"]
