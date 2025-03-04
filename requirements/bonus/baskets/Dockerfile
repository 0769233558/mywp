FROM alpine:3.18 as build

RUN apk add --no-cache git go

# Clone the repository
RUN go install github.com/darklynx/request-baskets@latest

# Expose port
EXPOSE 55555

# Start app
CMD ["/root/go/bin/request-baskets" ,"-l", "0.0.0.0"]
