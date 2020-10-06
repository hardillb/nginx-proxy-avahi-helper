FROM golang:1.14 as gobuilder

FROM gobuilder as dockergen

ENV DOCKER_GEN_VERSION 0.7.4
ADD https://github.com/jwilder/docker-gen/archive/${DOCKER_GEN_VERSION}.tar.gz sources.tar.gz

RUN tar -xzf sources.tar.gz && \
   mkdir -p /go/src/github.com/jwilder/ && \
   mv docker-gen-* /go/src/github.com/jwilder/docker-gen

WORKDIR /go/src/github.com/jwilder/docker-gen
RUN go get -v ./... && \
   CGO_ENABLED=0 GOOS=linux go build -ldflags "-X main.buildVersion=${DOCKER_GEN_VERSION}" ./cmd/docker-gen

FROM gobuilder as forego

ENV FOREGO_VERSION 0.16.1
ADD https://github.com/jwilder/forego/archive/v${FOREGO_VERSION}.tar.gz sources.tar.gz

RUN tar -xzf sources.tar.gz && \
   mkdir -p /go/src/github.com/ddollar/ && \
   mv forego-* /go/src/github.com/ddollar/forego

WORKDIR /go/src/github.com/ddollar/forego/
RUN go get -v ./... && \
   CGO_ENABLED=0 GOOS=linux go build -o forego .

FROM python:3.8.5-buster
LABEL maintainer="Ben Hardill hardillb@gmail.com"

RUN apt-get update && apt-get install -y libdbus-1-dev libdbus-glib-1-dev \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY --from=forego /go/src/github.com/ddollar/forego/forego /usr/local/bin/forego
COPY --from=dockergen /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/docker-gen

COPY Procfile .
COPY avahi.tmpl .
COPY cname.py .
COPY restart.sh .

RUN pip install mdns-publisher

ENV DOCKER_HOST unix:///tmp/docker.sock

CMD ["forego", "start", "-r"]
