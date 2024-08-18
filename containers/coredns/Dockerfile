FROM golang:1.23 AS build
RUN git clone https://github.com/coredns/coredns.git /coredns
WORKDIR /coredns
RUN sed -i 's#file:file#alternate:github.com/coredns/alternate\nfile:file#g' plugin.cfg && make

RUN export DEBCONF_NONINTERACTIVE_SEEN=true \
           DEBIAN_FRONTEND=noninteractive \
           DEBIAN_PRIORITY=critical \
           TERM=linux ; \
    apt-get -qq update ; \
    apt-get -yyqq upgrade ; \
    apt-get -yyqq install ca-certificates libcap2-bin; \
    apt-get clean
# COPY --from=0 /coredns/coredns /coredns
# RUN setcap cap_net_bind_service=+ep /coredns/coredns

# FROM gcr.io/distroless/static-debian11:nonroot
FROM gcr.io/distroless/static-debian12:latest
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /coredns/coredns /coredns
# USER nonroot:nonroot
EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
