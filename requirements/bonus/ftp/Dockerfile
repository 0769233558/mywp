FROM alpine:3.18

RUN apk add --no-cache python3 py3-pip
RUN pip install pyftpdlib

COPY tools/server.py /server.py

EXPOSE 21
CMD [ "python3", "/server.py" ]
