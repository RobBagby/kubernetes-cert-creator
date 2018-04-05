FROM ubuntu:17.10

ARG KUBECTL_VERSION=1.9.3
ARG IMAGE_CREATE_DATE
ARG IMAGE_VERSION
ARG IMAGE_SOURCE_REVISION

# Metadata
LABEL org.opencontainers.image.title="Kubernetes cert tool" \
      org.opencontainers.image.description="Creates a certificate request, requests approval in Kubernetes, gets the certificate and creates a new kubernetes config file based on the one passed in via environment var." \
      org.opencontainers.image.created=$IMAGE_CREATE_DATE \
      org.opencontainers.image.version=$IMAGE_VERSION \
      org.opencontainers.image.authors="Rob Bagby" \
      org.opencontainers.image.url="https://hub.docker.com/r/rbagby/kubernetes-cert-creator/" \
      org.opencontainers.image.documentation="https://github.com/robbagby/kubernetes-cert-creator" \
      org.opencontainers.image.vendor="Rob Bagby" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/robbagby/kubernetes-cert-creator" \
      org.opencontainers.image.revision=$IMAGE_SOURCE_REVISION 

# Install dependencies and create dirs
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    openssl

RUN mkdir /usr/src/certs

WORKDIR /tmp/install-utils

# Install kubectl 
# License: Apache-2.0
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl    

# Copy the script and make executable
COPY ./create-cert.sh /usr/local/bin
RUN tr -d '\15\32' < /usr/local/bin/create-cert.sh > /usr/local/bin/create-cert.sh
RUN chmod +x /usr/local/bin/create-cert.sh

RUN rm -fr /tmp/install-utils

WORKDIR /usr/local/bin
ENTRYPOINT /usr/local/bin/create-cert.sh