#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -e

### This script is for offline e2e
HELM_CHART_VERSION=$1
export IMAGE_VERSION=$1
export SPRAY_JOB_VERSION=$1
export TARGET_VERSION=$1
export VSPHERE_USER=$2
export VSPHERE_PASSWD=$3
export AMD_ROOT_PASSWORD=$4
export KYLIN_VM_PASSWORD=$5
export VSPHERE_HOST="10.64.56.11"
export ARM_SERVER_PASSWORD=$6
export RUNNER_NAME=$7
export SPRAY_JOB="m.daocloud.io/ghcr.io/kubean-io/spray-job:${SPRAY_JOB_VERSION}"
export REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
export IMG_REGISTRY="ghcr.m.daocloud.io"
export HELM_REPO="https://kubean-io.github.io/kubean-helm-chart"
KUBECONFIG_PATH="${HOME}/.kube"

CLUSTER_PREFIX="kubean-offline-$RANDOM"
export KUBECONFIG_FILE="${KUBECONFIG_PATH}/${CLUSTER_PREFIX}-host.config"
export OFFLINE_FLAG=true
export REGISTRY_PORT_AMD64=31500
export REGISTRY_PORT_ARM64=31501
export CONTAINERS_PREFIX="kubean-offline"
export REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
echo "HELM_CHART_VERSION: ${HELM_CHART_VERSION}"
NETWORK_CARD="ens192"
export RUNNER_NODE_IP=$(ip a |grep ${NETWORK_CARD}|grep inet|grep global|awk -F ' ' '{print $2}'|awk -F '/' '{print $1}')
export MINIO_URL="http://${RUNNER_NODE_IP}:32000"
export POWER_ON_SNAPSHOT_NAME="os-installed"
export POWER_DOWN_SNAPSHOT_NAME="power-down"
export E2eInstallClusterYamlFolder="e2e-install-cluster"
export LOCAL_REPO_ALIAS="kubean_release"
export LOCAL_RELEASE_NAME=kubean
#= export E2eInstallClusterYamlFolder="e2e-install-cluster"

chmod +x ${REPO_ROOT}/hack/offline_run_amd64.sh
chmod +x ${REPO_ROOT}/hack/offline_run_arm64.sh
chmod +x ${REPO_ROOT}/hack/offline_run_centos.sh
chmod +x ${REPO_ROOT}/hack/run-network-e2e.sh

export registry_addr_amd64=${RUNNER_NODE_IP}:${REGISTRY_PORT_AMD64}
export registry_addr_arm64=${RUNNER_NODE_IP}:${REGISTRY_PORT_ARM64}
local_helm_repo_alias="kubean_release"
source "${REPO_ROOT}"/hack/util.sh
source "${REPO_ROOT}"/hack/offline-util.sh
source "${REPO_ROOT}"/hack/resouce_util.sh

kind::clean_kind_cluster ${CONTAINERS_PREFIX}

repoCount=true
helm repo list |awk '{print $1}'| grep "${local_helm_repo_alias}" || repoCount=false
echo "repoCount: $repoCount"
if [ "$repoCount" != "false" ]; then
    helm repo remove ${local_helm_repo_alias}
fi
helm repo add ${local_helm_repo_alias} ${HELM_REPO} --force-update
helm repo list

KIND_VERSION="release-ci.daocloud.io/kpanda/kindest-node:v1.26.4"
./hack/local-up-kindcluster.sh "${HELM_CHART_VERSION}" "${IMAGE_VERSION}" "${HELM_REPO}" "${IMG_REGISTRY}" "${KIND_VERSION}" "${CLUSTER_PREFIX}"-host

### Set params in test/tools/offline_params.yml
sed -i "/ip:/c\ip: ${RUNNER_NODE_IP}"  ${REPO_ROOT}/test/tools/offline_params.yml
sed -i "/registry_addr_amd64:/c\registry_addr_amd64: ${registry_addr_amd64}"  ${REPO_ROOT}/test/tools/offline_params.yml
sed -i "/registry_addr_arm64:/c\registry_addr_arm64: ${registry_addr_arm64}"  ${REPO_ROOT}/test/tools/offline_params.yml
sed -i "/minio_addr:/c\minio_addr: ${MINIO_URL}"  ${REPO_ROOT}/test/tools/offline_params.yml
nginx_image_name="${registry_addr_amd64}/test/docker.m.daocloud.io/library/nginx:alpine"
sed -i "/nginx_image_amd64:/c\nginx_image_amd64: ${nginx_image_name} "  ${REPO_ROOT}/test/tools/offline_params.yml
nginx_image_name="${registry_addr_arm64}/test/docker.m.daocloud.io/arm64v8/nginx:1.23-alpine"
sed -i "/nginx_image_arm64:/c\nginx_image_arm64: ${nginx_image_name} "  ${REPO_ROOT}/test/tools/offline_params.yml

##### First AMD64 case ######
util::set_config_path
./hack/offline_run_arm64.sh
./hack/offline_run_amd64.sh

kind::clean_kind_cluster ${CONTAINERS_PREFIX}
