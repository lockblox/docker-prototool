FROM golang:1.11.0-alpine3.8 AS build

ARG PROTOTOOL_VERSION=1.3.0
ARG PROTOC_VERSION=3.6.1
ARG PROTOC_GEN_GO_VERSION=1.2.0

RUN \
  apk update && \
  apk add curl git libc6-compat && \
  rm -rf /var/cache/apk/*
RUN \
  curl -sSL https://github.com/uber/prototool/releases/download/v$PROTOTOOL_VERSION/prototool-Linux-x86_64 -o /bin/prototool && \
  chmod +x /bin/prototool
RUN \
  mkdir /tmp/prototool-bootstrap && \
  echo $'protoc:\n  version:' $PROTOC_VERSION > /tmp/prototool-bootstrap/prototool.yaml && \
  echo 'syntax = "proto3";' > /tmp/prototool-bootstrap/tmp.proto && \
  prototool compile /tmp/prototool-bootstrap && \
  rm -rf /tmp/prototool-bootstrap
RUN go get github.com/golang/protobuf/... && \
  cd /go/src/github.com/golang/protobuf && \
  git checkout v$PROTOC_GEN_GO_VERSION && \
  go install ./protoc-gen-go

FROM alpine:3.8

WORKDIR /in

RUN \
  apk update && \
  apk add libc6-compat && \
  rm -rf /var/cache/apk/*

COPY --from=build /bin/prototool /bin/prototool
COPY --from=build /root/.cache/prototool /root/.cache/prototool
COPY --from=build /go/bin/protoc-gen-go /bin/protoc-gen-go

ENTRYPOINT ["/bin/prototool"]