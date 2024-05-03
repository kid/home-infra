FROM alpine as build
ENV VERSION=0.21.0
ENV CHECKSUM=d3886d95647287898080ac72fd322b68587504679c526f72718cab45fc366e8a

ADD https://github.com/stefanprodan/timoni/releases/download/v${VERSION}/timoni_${VERSION}_linux_amd64.tar.gz /tmp
RUN DOWNLOAD_FILE="/tmp/timoni_${VERSION}_linux_amd64.tar.gz" && \
    DOWNLOAD_CHECKSUM=$(sha256sum "${DOWNLOAD_FILE}" | awk '{print $1}') && \
    if [[ ${DOWNLOAD_CHECKSUM} != ${CHECKSUM} ]]; then \
      echo "Checksum does not match"; \
      exit 1; \
    fi && \
    tar xzf "${DOWNLOAD_FILE}" -C / && \
    rm "${DOWNLOAD_FILE}"

FROM scratch
COPY --from=build timoni .
COPY run.sh .
