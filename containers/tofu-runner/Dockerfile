ARG TF_CONTROLLER_VERSION
FROM ghcr.io/flux-iac/tf-runner:${TF_CONTROLLER_VERSION}

ARG TARGETARCH
ARG TF_VERSION

USER root

ADD https://github.com/opentofu/opentofu/releases/download/v${TF_VERSION}/tofu_${TF_VERSION}_linux_${TARGETARCH}.zip /tofu_${TF_VERSION}_linux_${TARGETARCH}.zip
RUN unzip -q /tofu_${TF_VERSION}_linux_${TARGETARCH}.zip -d /usr/local/bin && \
    mv /usr/local/bin/tofu /usr/local/bin/terraform && \
    chmod +x /usr/local/bin/terraform && \
    rm /tofu_${TF_VERSION}_linux_${TARGETARCH}.zip

USER 65532:65532
