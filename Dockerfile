ARG DOCKER_GEN_VERSION=0.10.6
ARG FOREGO_VERSION=v0.17.2
ARG PYTHON_VER=3.11

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

FROM python:${PYTHON_VER} as pythonbuilder
RUN apt-get update && apt-get install -y build-essential libdbus-1-dev
RUN pip install mdns-publisher

FROM python:${PYTHON_VER}-slim
LABEL maintainer="Ben Hardill hardillb@gmail.com"
ARG PYTHON_VER

RUN apt-get update && apt-get install -y libdbus-1-3 && rm -rf /var/lib/apt/lists/*

COPY --from=forego /usr/local/bin/forego /usr/local/bin/forego
COPY --from=dockergen /usr/local/bin/docker-gen  /usr/local/bin/docker-gen
COPY --from=pythonbuilder /usr/local/lib/python${PYTHON_VER}/site-packages/ /usr/local/lib/python${PYTHON_VER}/site-packages/

WORKDIR /usr/src/app

COPY Procfile .
COPY avahi.tmpl .
COPY cname.py .
COPY restart.sh .
RUN touch ./cnames

ENV DOCKER_HOST unix:///tmp/docker.sock

CMD ["forego", "start", "-r"]
