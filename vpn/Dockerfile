FROM ryansch/wireguard:latest
MAINTAINER Ryan Schlesinger <ryan@outstand.com>

RUN mkdir -p /etc/wireguard/lock
COPY entrypoint.sh /prod-entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/prod-entrypoint.sh"]
