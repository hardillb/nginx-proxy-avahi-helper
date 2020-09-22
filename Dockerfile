FROM python:3.8.5-buster
LABEL maintainer="Ben Hardill hardillb@gmail.com"

RUN apt-get update && apt-get install -y libdbus-1-dev libdbus-glib-1-dev \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY forego /usr/local/bin
COPY docker-gen /usr/local/bin

COPY Procfile .
COPY avahi.tmpl .
COPY cname.py .
COPY restart.sh .

RUN pip install mdns-publisher

ENV DOCKER_HOST unix:///tmp/docker.sock

CMD ["forego", "start", "-r"]
