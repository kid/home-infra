FROM alpine:3.20.0

RUN addgroup -S -g 10001 dnsdist && \
    adduser -S -D -u 10001 -G dnsdist dnsdist && \
    mkdir -p /etc/dnsdist /var/lib/dnsdist && \
    touch /etc/dnsdist/blocklist.txt && \
    apk add --no-cache dnsdist=1.9.4-r0

VOLUME ["/var/lib/dnsdist"]

EXPOSE 53/tcp 53/udp 443/tcp 853/tcp 8083/tcp 8443/tcp 8443/udp

CMD ["dnsdist", "--supervised", "--disable-syslog", "--uid", "dnsdist", "--gid", "dnsdist", "-C", "/etc/dnsdist.d/dnsdist.conf"]
