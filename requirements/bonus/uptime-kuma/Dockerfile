FROM alpine:3.18

ENV UK_USER="uptime-kuma" \
	UK_PASSWORD="uptime-kuma"

RUN apk add --no-cache git nodejs-current npm python3 py3-pip

RUN git clone https://github.com/louislam/uptime-kuma.git /uptime-kuma
WORKDIR /uptime-kuma
RUN git checkout 1.18.5

# Install dependencies
RUN npm run setup
RUN pip install uptime-kuma-api==0.5.1

COPY tools/docker-entrypoint.sh /usr/local/bin/
COPY tools/configure-uptime-kuma.py /

EXPOSE 3001
ENTRYPOINT ["sh", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "/uptime-kuma/server/server.js"]
