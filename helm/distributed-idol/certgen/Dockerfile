FROM golang:1.12

WORKDIR /generator

RUN go get -u github.com/cloudflare/cfssl/cmd/...

COPY gen.sh /generator/gen.sh

RUN chmod +x /generator/gen.sh

ENTRYPOINT [ "./gen.sh" ]