#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -x

function init_vars_airgap_resource_download(){
  export NEW_TAG=$1
  export STEP_TYPE=$2  # value1: DOWNLOAD;value2: BUILD
  echo "${NEW_TAG}" "${STEP_TYPE}"
  BASE_URL="https://files.m.daocloud.io/github.com/kubean-io/kubean/releases/download"
  if [[ ${STEP_TYPE} == "DOWNLOAD" ]];then
    export FILE_PART_NAME=$3
  fi
  export DOWNLOAD_ROOT_FOLDER="/root/release_files_download"
  export TAG_FILE="${DOWNLOAD_ROOT_FOLDER}/${NEW_TAG}/tag.txt"
}


function util::check_file(){
  download_file_name=$1
  old_tag="v0.0"
  if [[ ! -f ${TAG_FILE} ]];then
    echo "tag file is not exsit, touch it."
    rm -fr ${DOWNLOAD_ROOT_FOLDER}/"${NEW_TAG}"
    mkdir -p ${DOWNLOAD_ROOT_FOLDER}/"${NEW_TAG}"
    echo "tag=${NEW_TAG}" > "${TAG_FILE}"
  else
    old_tag=$(cat ${TAG_FILE}|grep "tag"|awk -F "=" '{print $2}')
    echo "old tag is: ${old_tag}"
    if [[ "${old_tag}" != "${NEW_TAG}" ]];then
      rm -fr ${DOWNLOAD_ROOT_FOLDER}/"${NEW_TAG}"
      mkdir -p ${DOWNLOAD_ROOT_FOLDER}/"${NEW_TAG}"
      echo "tag=${NEW_TAG}" > "${TAG_FILE}"
    else
      echo "tag is equal."
    fi
  fi
  util::wget_file "${FILE_PART_NAME}"
}

function util::wget_file(){
  file_part_name=$1
  local_file="${DOWNLOAD_ROOT_FOLDER}/${NEW_TAG}/${FILE_PART_NAME}-${NEW_TAG}.tar.gz"
  if [[ -f "${local_file}" ]];then
    echo "${file_part_name} is exist, nothing to do"
  else
    echo "${file_part_name} not exists, download it..."
    file_url=${BASE_URL}/${NEW_TAG}/${FILE_PART_NAME}-${NEW_TAG}.tar.gz
    wget -q -c -T 1m -P "${DOWNLOAD_ROOT_FOLDER}/${NEW_TAG}" "${file_url}"
    echo "Download file end."
  fi
}


function main() {
  init_vars_airgap_resource_download $@
  if [[ ${STEP_TYPE} == "DOWNLOAD" ]];then
   util::check_file  "${FILE_PART_NAME}"
  fi
}

main $@