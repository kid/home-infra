FROM alpine as build
ENV VERSION=0.16.6
ENV CHECKSUM=3172f3ca66df44233f39bcc2c43c4c149ed90da29acd1da44e8efd498828cf93

ADD https://github.com/cilium/cilium-cli/releases/download/v${VERSION}/cilium-linux-amd64.tar.gz /tmp
RUN DOWNLOAD_FILE="/tmp/cilium-linux-amd64.tar.gz" && \
    DOWNLOAD_CHECKSUM=$(sha256sum "${DOWNLOAD_FILE}" | awk '{print $1}') && \
    if [[ ${DOWNLOAD_CHECKSUM} != ${CHECKSUM} ]]; then \
      echo "Checksum does not match"; \
      exit 1; \
    fi && \
    tar xzf "${DOWNLOAD_FILE}" -C / && \
    rm "${DOWNLOAD_FILE}"

FROM scratch
COPY --from=build cilium .
COPY cilium-install.service .
COPY cilium-install.sh .
COPY run.sh .
