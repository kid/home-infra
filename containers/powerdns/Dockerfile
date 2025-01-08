FROM alpine:3.21.2

ARG PDNS_VERSION=4.9.2-r0

RUN addgroup -S -g 10001 pdns && \
    adduser -S -D -u 10001 -G pdns pdns && \
    mkdir -p /etc/pdns /var/lib/powerdns && \
    chown -R pdns:pdns /var/lib/powerdns && \
    apk add --no-cache pdns=$PDNS_VERSION pdns-backend-sqlite3=$PDNS_VERSION pdns-doc=$PDNS_VERSION tini=0.19.0-r3

# USER pdns

VOLUME ["/var/lib/powerdns"]

EXPOSE 53/tcp 53/udp 8081/tcp

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]

CMD ["pdns_server", "--daemon=no", "--disable-syslog=yes", "--setuid=pdns", "--setgid=pdns"]
