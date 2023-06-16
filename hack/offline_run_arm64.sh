#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "${REPO_ROOT}"/hack/util.sh
source "${REPO_ROOT}"/hack/offline-util.sh
export registry_addr_arm64=${RUNNER_NODE_IP}:${REGISTRY_PORT_ARM64}
util::scope_copy_test_images ${registry_addr_arm64}

#####################################
function func_prepare_config_yaml_kylin_offline() {
    local source_path=$1
    local dest_path=$2
    rm -fr "${dest_path}"
    mkdir "${dest_path}"

    cp -f  ${source_path}/hosts-conf-cm-2nodes.yml "${dest_path}"
    cp -f  ${source_path}/kubeanCluster.yml "${dest_path}"
    cp -f  ${source_path}/kubeanClusterOps.yml "${dest_path}"
    cp -f   ${source_path}/vars-conf-cm.yml "${dest_path}"
    # host-config-cm.yaml set
    sed -i "s/vm_ip_addr1/${vm_ip_addr1}/g" ${dest_path}/hosts-conf-cm.yml
    sed -i "s/vm_ip_addr2/${vm_ip_addr2}/g" ${dest_path}/hosts-conf-cm.yml
    sed -i "s/root_password/${KYLIN_VM_PASSWORD}/g" ${dest_path}/hosts-conf-cm.yml
    # kubeanClusterOps.yml sed
    sed -i "s#image:#image: ${SPRAY_JOB}#" ${dest_path}/kubeanClusterOps.yml
    sed -i "s#e2e-cluster1-install#${CLUSTER_OPERATION_NAME1}#" ${dest_path}/kubeanClusterOps.yml
    sed -i "s#{offline_minio_url}#${MINIO_URL}#g" ${dest_path}/kubeanClusterOps.yml
    sed -i  "s#centos#kylin#g" ${dest_path}/kubeanClusterOps.yml
    # vars-conf-cm.yml set
    sed -i "s#registry_host:#registry_host: ${registry_addr_arm64}#"    ${dest_path}/vars-conf-cm.yml
    sed -i "s#minio_address:#minio_address: ${MINIO_URL}#"    ${dest_path}/vars-conf-cm.yml
    sed -i "s#registry_host_key#${registry_addr_arm64}#g"    ${dest_path}/vars-conf-cm.yml
    sed -i "s#{{ files_repo }}/centos#{{ files_repo }}/kylin#" ${dest_path}/vars-conf-cm.yml
}


function case::create_kylin_cluster(){
  local cri_type=${1:-"containerd"}
  #### prepare config yaml #####
  CLUSTER_OPERATION_NAME1="cluster1-install-"`date "+%H-%M-%S"`
  go_test_path="test/kubean_os_compatibility_e2e"
  dest_config_path="${REPO_ROOT}"/${go_test_path}/"${E2eInstallClusterYamlFolder}-kylin-${cri_type}"
  func_prepare_config_yaml_kylin_offline  ${SOURCE_CONFIG_PATH} ${dest_config_path}
  sed -i "s#e2e-cluster1-install#${CLUSTER_OPERATION_NAME1}#" ${dest_config_path}/kubeanClusterOps.yml

  #### run cri of docker and containerd ####
  if [[ ${cri_type}} =~ "docker" ]];then
    sed -i "s/containerd/docker/" ${dest_config_path}/vars-conf-cm.yml
  fi
  #### prepare vms ####
  util::vm_name_ip_init_offline_by_os  ${os_name}
  util::init_kylin_vm_template_map
  util::init_kylin_vm ${template_name1} ${vm_name1} ${ARM64_SERVER_IP} ${ARM64_SERVER_PASSWORD}
  util::init_kylin_vm ${template_name2} ${vm_name2} ${ARM64_SERVER_IP} ${ARM64_SERVER_PASSWORD}
  echo "wait ${vm_ip_addr1} ..."
  util::wait_ip_reachable "${vm_ip_addr1}" 30
  echo "wait ${vm_ip_addr2} ..."
  util::wait_ip_reachable "${vm_ip_addr2}" 30

  #### run case ####
  ginkgo -v -timeout=10h -race --fail-fast ./${go_test_path}  -- \
      --kubeconfig="${KUBECONFIG_FILE}" \
      --clusterOperationName="${CLUSTER_OPERATION_NAME1}" --vmipaddr="${vm_ip_addr1}" --vmipaddr2="${vm_ip_addr2}" \
      --isOffline="true"  --vmPassword="${KYLIN_VM_PASSWORD}"  --arch=${arch}

  #### tear down ####
  util::delete_kylin_vm ${vm_name1} ${ARM64_SERVER_IP} ${ARM64_SERVER_PASSWORD}
  util::delete_kylin_vm ${vm_name2} ${ARM64_SERVER_IP} ${ARM64_SERVER_PASSWORD}
  echo "Delete vm end!"
}

#####################################
# shellcheck disable=SC1130
function main(){
  ARM64_SERVER_PASSWORD=$1
  ARM64_SERVER_IP="10.0.6.17"
  os_name="kylinv10"
  arch="arm64"
  cri_list=("docker" "containerd")
  for cri in "${cri_list[@]}";do
   echo "#### CASE: CREATE KYLIN CLUSTER WITH ${cri} ####"
   case::create_kylin_cluster ${cri}
  done
}

main $@




