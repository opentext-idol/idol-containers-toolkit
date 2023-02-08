# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2022 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE
FROM golang:1.19

WORKDIR /generator

RUN go install github.com/cloudflare/cfssl/cmd/...@v1.6.2

COPY gen.sh /generator/gen.sh

RUN chmod +x /generator/gen.sh

ENTRYPOINT [ "./gen.sh" ]