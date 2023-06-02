#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function util::init_env_base_e2e(){

  export REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
  export VSPHERE_HOST="10.64.56.11"
  export IMG_REGISTRY="ghcr.m.daocloud.io"
  export HELM_REPO="https://kubean-io.github.io/kubean-helm-chart"
  KUBECONFIG_PATH="${HOME}/.kube"
  export KUBECONFIG_FILE="${KUBECONFIG_PATH}/${CLUSTER_PREFIX}-host.config"
  if [[ ${OFFLINE_FLAG} == true ]];then
   CLUSTER_PREFIX="kubean-offline-$RANDOM"
  else
    CLUSTER_PREFIX="kubean-online-$RANDOM"
  fi
}



function util::init_vars_offline_e2e(){
  export IMAGE_VERSION=$1
  export HELM_CHART_VERSION=$1
  export VSPHERE_USER=$2
  export VSPHERE_PASSWD=$3
  export AMD_ROOT_PASSWORD=$4
  export VM_PASSWORD=$5
  export RUNNER_NAME=$6
  export SPRAY_JOB="m.daocloud.io/ghcr.io/kubean-io/spray-job:${IMAGE_VERSION}"





  export OFFLINE_FLAG=true
  #export REGISTRY_PORT_AMD64=31500
  #export REGISTRY_PORT_ARM64=31501
  #export MINIOUSER="admin"
  #export MINIOPWD="adminPassword"
  #export MINIOPORT=32000
  export CONTAINERS_PREFIX="kubean-offline"
  export DOWNLOAD_FOLDER="${REPO_ROOT}/download_offline_files-${TARGET_VERSION}"
  export REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
  NETWORK_CARD="ens192"
  export RUNNER_NODE_IP=$(ip a |grep ${NETWORK_CARD}|grep inet|grep global|awk -F ' ' '{print $2}'|awk -F '/' '{print $1}')
  export MINIO_URL=http://${RUNNER_NODE_IP}:${MINIOPORT}
  export POWER_ON_SNAPSHOT_NAME="os-installed"
  export POWER_DOWN_SNAPSHOT_NAME="power-down"
  export E2eInstallClusterYamlFolder="e2e-install-cluster"
  export LOCAL_REPO_ALIAS="kubean_release"
  export LOCAL_RELEASE_NAME=kubean
  #= export E2eInstallClusterYamlFolder="e2e-install-cluster"

  chmod +x ${REPO_ROOT}/hack/*.sh


  export NEW_TAG=$1
  export STEP_TYPE=$2
  export DOWNLOAD_ROOT_FOLDER="/root/release_files_download"
  echo "${NEW_TAG}" "${STEP_TYPE}"
  if [[ ${STEP_TYPE} == "DOWNLOAD" ]];then
    export TAG_FILE="${DOWNLOAD_ROOT_FOLDER}/tag.txt"
  elif [[ ${STEP_TYPE} == "BUILD" ]];then
    export RESOURCE_SVC_TAG_FILE="/root/resource_svc_tag/${NEW_TAG}.txt"
  fi

  export KUBECONFIG_FILE="/root/.kube/airgap_resource.config"
  export KIND_NAME="airgap-resource"
  export kindRun="docker exec -i  --privileged ${KIND_NAME}-control-plane  bash -c"
  MINIO_USER="admin"
  MINIO_PASS="adminpass123"
  MINIO_URL="http://127.0.0.1:32000"
  source "${REPO_ROOT}"/hack/tools/util.sh
}