FROM golang:1.19

WORKDIR /generator

RUN go install github.com/cloudflare/cfssl/cmd/...@v1.6.2

COPY gen.sh /generator/gen.sh

RUN chmod +x /generator/gen.sh

ENTRYPOINT [ "./gen.sh" ]