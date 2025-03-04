#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.18

# persistent / runtime deps
RUN apk add --no-cache git python3

# ensure www-data user exists
RUN set -eux; \
	adduser -u 82 -D -S -G www-data www-data
# 82 is the standard uid/gid for "www-data" in Alpine

COPY tools/docker-php-* /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-php*

RUN set -eux; \
	[ ! -d /var/www/html/revshells ]; \
	mkdir -p /var/www/html/revshells; \
	chown -R www-data:www-data /var/www/html; \
	chmod 1755 /var/www/html/revshells;

STOPSIGNAL SIGQUIT

EXPOSE 8080
USER www-data
ENTRYPOINT ["sh", "/usr/local/bin/docker-php-entrypoint"]
WORKDIR /var/www/html/revshells
CMD ["revshells"]
