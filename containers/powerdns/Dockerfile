FROM alpine:3.20.0

RUN addgroup -S -g 10001 pdns && \
    adduser -S -D -u 10001 -G pdns pdns && \
    mkdir -p /etc/pdns /var/lib/powerdns && \
    chown -R pdns:pdns /var/lib/powerdns && \
    apk add --no-cache pdns=4.9.1-r0 pdns-backend-sqlite3=4.9.1-r0 pdns-doc=4.9.1-r0 tini=0.19.0-r3

# USER pdns

VOLUME ["/var/lib/powerdns"]

EXPOSE 53/tcp 53/udp 8081/tcp

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]

CMD ["pdns_server", "--daemon=no", "--disable-syslog=yes", "--setuid=pdns", "--setgid=pdns"]
