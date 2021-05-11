FROM python:3.9-slim-buster

RUN pip install --upgrade pip awscli && \
    apt-get update && apt-get install --no-install-recommends -y \
    curl \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/*


ENV HELM_VERSION=3.5.4

RUN curl -f https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar  xzv --strip-components=1 -C /usr/bin/ linux-amd64/helm

ENV YQ_VERSION=3.3.0

RUN curl -L https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

ENV KUBECTL_VERSION="1.18.9"
RUN set -x & \
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/bin/kubectl

ENV HELMFILE_VERSION="0.139.3"
RUN set -x & \
    curl -LO "https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64" && \
    chmod +x helmfile_linux_amd64 && \
    mv helmfile_linux_amd64 /usr/bin/helmfile

ENV SOPS_VERSION="3.7.1"
RUN set -x & \
    curl -LO "https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v3.7.1.linux" && \
    chmod +x sops-v3.7.1.linux && \
    mv sops-v3.7.1.linux /usr/bin/sops

RUN helm plugin install https://github.com/databus23/helm-diff && \
    helm plugin install https://github.com/futuresimple/helm-secrets

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
