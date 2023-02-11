ARG DOCKER_GEN_VERSION=0.10.0
ARG FOREGO_VERSION=v0.17.0

FROM golang:1.20 as gobuilder

FROM gobuilder as dockergen

ARG DOCKER_GEN_VERSION

RUN git clone https://github.com/nginx-proxy/docker-gen \
   && cd /go/docker-gen \
   && git -c advice.detachedHead=false checkout $DOCKER_GEN_VERSION \
   && go mod download \
   && CGO_ENABLED=0 GOOS=linux go build -ldflags "-X main.buildVersion=${DOCKER_GEN_VERSION}" ./cmd/docker-gen \
   && go clean -cache \
   && mv docker-gen /usr/local/bin/ \
   && cd - \
   && rm -rf /go/docker-gen

# Build forego from scratch
FROM gobuilder as forego

ARG FOREGO_VERSION

RUN git clone https://github.com/nginx-proxy/forego/ \
   && cd /go/forego \
   && git -c advice.detachedHead=false checkout $FOREGO_VERSION \
   && go mod download \
   && CGO_ENABLED=0 GOOS=linux go build -o forego . \
   && go clean -cache \
   && mv forego /usr/local/bin/ \
   && cd - \
   && rm -rf /go/forego


FROM python:3.9.16-bullseye
LABEL maintainer="Ben Hardill hardillb@gmail.com"

RUN apt-get update && apt-get install -y build-essential ninja-build patchelf cmake libdbus-1-dev libdbus-glib-1-dev \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY --from=forego /usr/local/bin/forego /usr/local/bin/forego
COPY --from=dockergen /usr/local/bin/docker-gen  /usr/local/bin/docker-gen

COPY Procfile .
COPY avahi.tmpl .
COPY cname.py .
COPY restart.sh .

RUN pip install mdns-publisher

ENV DOCKER_HOST unix:///tmp/docker.sock

CMD ["forego", "start", "-r"]
