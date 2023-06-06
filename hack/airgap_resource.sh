#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail


# shellcheck disable=SC1090
source "${REPO_ROOT}"/hack/tools/*.sh
util::init_vars_offline_resource_download $@

if [[ ${STEP_TYPE} == "DOWNLOAD" ]];then
  result=$(util::check_file_tag ${NEW_TAG} ${TAG_FILE})
  if [[ "${result}"  =~ "YES" ]];then
    echo "Check file tag ok"
     result=$(util::check_file_integrity  ${NEW_TAG} ${DOWNLOAD_ROOT_FOLDER})
    if [[ "${result}"  =~ "YES" ]];then
      echo "Check file integrity ok"
      exit 0
    fi
  fi

  util::delete_redundant_folders ${NEW_TAG} ${DOWNLOAD_ROOT_FOLDER}
  echo "Start download file..."
  util::download_file_list ${NEW_TAG} ${DOWNLOAD_ROOT_FOLDER}
  util::write_tag_file ${NEW_TAG} ${TAG_FILE}

  echo "Download file finished"
elif [[ ${STEP_TYPE} == "BUILD" ]];then
  result_kind_cluster=$(util::check_kind_cluster_by_name "${KIND_NAME}" "${KUBECONFIG_FILE}")
  result_minio=$(util::check_minio)
  result_registry=$(util::check_registry)
  result_version=$(util::check_resource_svc_version "${RESOURCE_SVC_TAG_FILE}" "${NEW_TAG}")
  if [[ ${result_kind_cluster} =~ "YES" ]] && [[ ${result_minio} =~ "YES" ]] && [[ ${result_registry} =~ "YES" ]] && [[ ${result_version} =~ "YES" ]];then
    echo "Check registry and minio ok"
  else
    echo "reinstall all resource..."
    util::clean_kind_cluster "${KIND_NAME}"
    util::create_kind_cluster_by_config_file  "${KIND_NAME}" "${KUBECONFIG_FILE}"
    util::install_minio "${KUBECONFIG_FILE}"
    util::install_registry "AMD64" "${KUBECONFIG_FILE}" "registry-amd64"
    util::install_registry "ARM64" "${KUBECONFIG_FILE}" "registry-arm64"
    util::import_files_minio_by_arch "${DOWNLOAD_ROOT_FOLDER}"  "${NEW_TAG}"
    util::import_files_minio_by_arch "${DOWNLOAD_ROOT_FOLDER}"  "${NEW_TAG}"
    util::import_iso_minio "${NEW_TAG}"
    util::import_os_package_minio "${DOWNLOAD_ROOT_FOLDER}"  "${NEW_TAG}"
    util::write_offline_resource_service_tag "${RESOURCE_SVC_TAG_FILE}" "${NEW_TAG}"
   echo "Rebuild resource end :)"
  fi

fi