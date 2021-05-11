#!/bin/bash
set -euo pipefail

PLUGIN_NAMESPACE=${PLUGIN_NAMESPACE:-${NAMESPACE:-default}}
PLUGIN_KUBERNETES_USER=${PLUGIN_KUBERNETES_USER:-${KUBERNETES_USER:-default}}
PLUGIN_KUBERNETES_TOKEN=${PLUGIN_KUBERNETES_TOKEN:-"${KUBERNETES_TOKEN}"}
PLUGIN_KUBERNETES_SERVER=${PLUGIN_KUBERNETES_SERVER:-"${KUBERNETES_SERVER}"}
PLUGIN_KUBERNETES_CERT=${PLUGIN_KUBERNETES_CERT:-"${KUBERNETES_CERT}"}

if [ -n "${PLUGIN_NAMESPACE}" ] && [  -n "${PLUGIN_KUBERNETES_USER}" ] && [ -n "${PLUGIN_KUBERNETES_TOKEN}" ] && [ -n "${PLUGIN_KUBERNETES_SERVER}" ]; then
    kubectl config set-credentials default --token="${PLUGIN_KUBERNETES_TOKEN}"

    if [ -n "${PLUGIN_KUBERNETES_CERT}" ]; then
      echo "${PLUGIN_KUBERNETES_CERT}" | base64 -d > ca.crt
      kubectl config set-cluster default --server="${PLUGIN_KUBERNETES_SERVER}" --certificate-authority=ca.crt
    else
      echo "WARNING: Using insecure connection to cluster"
      kubectl config set-cluster default --server="${PLUGIN_KUBERNETES_SERVER}" --insecure-skip-tls-verify=true
    fi

    kubectl config set-context default --cluster=default --user="${PLUGIN_KUBERNETES_USER}"
    kubectl config use-context default
fi

PLUGIN_REGISTRY=${PLUGIN_REGISTRY:-}
PLUGIN_APP_NAME=${PLUGIN_APP_NAME:-$(basename "${DRONE_REMOTE_URL}" .git)}
PLUGIN_APP_IMAGE_PATH="${PLUGIN_APP_IMAGE_PATH:-$PLUGIN_REGISTRY/$PLUGIN_APP_NAME}"
PLUGIN_VERSION=${PLUGIN_VERSION:-${DRONE_COMMIT:0:7}}
PLUGIN_RELEASE_NAME=${PLUGIN_RELEASE_NAME:-${PLUGIN_APP_NAME}}


cat << EOF > global.yaml
image:
  repository: "${PLUGIN_APP_IMAGE_PATH}"
  tag: "${PLUGIN_VERSION}"
EOF

if  [[ -z ${destroy+x} ]]; then
  action="apply --values global.yaml"
else
  action="destroy"
fi

if [[ -z ${entrypoint+x} ]]; then
  helmfile --environment "${DRONE_DEPLOY_TO}" --selector name="${PLUGIN_RELEASE_NAME}-${DRONE_DEPLOY_TO}" ${action}
else
  helmfile --environment "${DRONE_DEPLOY_TO}" --selector name="${PLUGIN_RELEASE_NAME}-entrypoint" ${action}
fi
