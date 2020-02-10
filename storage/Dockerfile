FROM python:3-alpine
MAINTAINER Ryan Schlesinger <ryan@outstand.com>

RUN pip install awscli
RUN mkdir -p /etc/wireguard/lock

VOLUME /etc/wireguard
WORKDIR /etc/wireguard

COPY sync.sh upload.sh /usr/local/bin/
CMD ["sync.sh"]
