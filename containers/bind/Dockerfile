FROM alpine:3.21.2

RUN mkdir -p /etc/bind  && \
    apk add --no-cache bind=9.18.27-r0


COPY entrypoint.sh /entrypoint.sh

VOLUME ["/etc/bind" "/var/cache/bind" "/var/lib/bind"]
EXPOSE 53/tcp 53/udp 953/tcp
ENTRYPOINT ["/entrypoint.sh"]
CMD ["named", "-g", "-u", "named", "-c", "/etc/bind/named.conf"]
