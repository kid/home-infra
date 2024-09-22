FROM --platform=$BUILDPLATFORM golang:1.23 AS build

ARG TARGETOS
ARG TARGETARCH

WORKDIR /src
RUN --mount=target=. \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /coredns .


FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /coredns /coredns
# USER nonroot:nonroot
EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
