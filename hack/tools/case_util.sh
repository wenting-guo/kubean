#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

## This document contains functions used in the test case
function util::init_env_for_shell(){
  declare -u offline_flag=$1
  util::init_common_env
  if [[ ${offline_flag} == "true" ]]; then
    util::init_offline_env
  else
    util::init_online_env
  fi
}

# shellcheck disable=SC2120
function util::init_common_env(){
    export OFFLINE_FLAG=$1
    export TARGET_VERSION=$2
    export IMAGE_VERSION=$3
    export RUNNER_NAME=$4
    export VSPHERE_USER=$5
    export VSPHERE_PASSWD=$6
    export VM_ROOT_PASSWORD=$7
    export VSPHERE_HOST=$8
    export IMG_REPO="ghcr.io/kubean-io"
    export HELM_REPO="https://kubean-io.github.io/kubean-helm-chart"
    export SPRAY_JOB="??????"
    export KUBECONFIG_PATH="${HOME}/.kube"
    export KUBECONFIG_FILE="${KUBECONFIG_PATH}/${CLUSTER_PREFIX}-host.config"
    export REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
    export LOCAL_REPO_ALIAS="kubean_release"
    export LOCAL_RELEASE_NAME="kubean"
}
function util::init_offline_env(){
    export CONTAINERS_PREFIX="kubean-offline"
    export CLUSTER_PREFIX=${CONTAINERS_PREFIX}-$RANDOM
}

function util::init_online_env(){
    export E2E_TYPE=$9
    export CONTAINERS_PREFIX="kubean-online"  # 脚本中设置值
    export CLUSTER_PREFIX=${CONTAINERS_PREFIX}-$RANDOM  # 脚本中设置值
    #  pre to delete
    export SOURCE_CONFIG_PATH=${REPO_ROOT}/test/common   # 脚本中设置值="${REPO_ROOT}/test/common"
}

function util::power_on_2vms(){
  local OS_NAME=$1
  echo "OS_NAME is: ${OS_NAME}"
  if [[ ${OFFLINE_FLAG} == "true" ]]; then
    util::vm_name_ip_init_offline_by_os ${OS_NAME}
  else
    util::vm_name_ip_init_online_by_os ${OS_NAME}
  fi
  echo "vm_name1: ${vm_name1}"
  echo "vm_name2: ${vm_name2}"
  SNAPSHOT_NAME=${POWER_ON_SNAPSHOT_NAME}
  util::restore_vsphere_vm_snapshot ${VSPHERE_HOST} ${VSPHERE_PASSWD} ${VSPHERE_USER} "${SNAPSHOT_NAME}" "${vm_name1}"
  util::restore_vsphere_vm_snapshot ${VSPHERE_HOST} ${VSPHERE_PASSWD} ${VSPHERE_USER} "${SNAPSHOT_NAME}" "${vm_name2}"
  sleep 20
  util::wait_ip_reachable "${vm_ip_addr1}" 30
  util::wait_ip_reachable "${vm_ip_addr2}" 30
  ping -c 5 ${vm_ip_addr1}
  ping -c 5 ${vm_ip_addr2}
}

# shellcheck disable=SC1036
function util::vm_name_ip_init(){
  declare -u offline_flag=$1
  declare -u runner_name=$2
  declare -u os_name=$3
  local config_file=$4
  if [ -f ${config_file} ] ;then
    yq r
  else
    echo "vm config file ${config_file} not exists, exit now!"
    exit 1
  fi
}