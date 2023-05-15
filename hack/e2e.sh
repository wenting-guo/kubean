#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -e

# This script schedules e2e tests
# Parameters:
#[TARGET_VERSION] apps ta ge images/helm-chart revision( image and helm versions should be the same)
#[IMG_REGISTRY](optional) the image repository to be pulled from
#[HELM_REPO](optional) the helm chart repo to be pulled from

chmod -R +x ./hack
source ./hack/tools/*.sh

# add kubean repo locally
util::kubean_repo_prepare

DIFF_NIGHTLYE2E=`git show -- './test/*' | grep nightlye2e || true`
DIFF_COMPATIBILE=`git show | grep /test/kubean_os_compatibility_e2e || true`

####### e2e logic ########
if [ "${E2E_TYPE}" == "KUBEAN-COMPATIBILITY" ]; then
    k8s_list=( "v1.20.15" "v1.21.14" "v1.22.15" "v1.23.13" "v1.24.7" "v1.25.3" "v1.26.0" "v1.27.1" )
    echo ${#k8s_list[@]}
    for k8s in "${k8s_list[@]}"; do
        echo "***************k8s version is: ${k8s} ***************"
        util::clean_online_kind_cluster
        KIND_VERSION="release-ci.daocloud.io/kpanda/kindest-node:"${k8s}
        ./hack/local-up-kindcluster.sh "${TARGET_VERSION}" "${IMAGE_VERSION}" "${HELM_REPO}" "${IMG_REGISTRY}" "${KIND_VERSION}" "${CLUSTER_PREFIX}"-host
        ./hack/kubean_compatibility_e2e.sh
    done

else
    util::clean_online_kind_cluster
    KIND_VERSION="release-ci.daocloud.io/kpanda/kindest-node:v1.26.0"
    ./hack/local-up-kindcluster.sh "${TARGET_VERSION}" "${IMAGE_VERSION}" "${HELM_REPO}" "${IMG_REGISTRY}" "${KIND_VERSION}" "${CLUSTER_PREFIX}"-host
    util::set_config_path
    if [ "${E2E_TYPE}" == "PR" ]; then
        echo "RUN PR E2E......."
        ./hack/run-e2e.sh
        if [[ -n $DIFF_NIGHTLYE2E ]] ; then
            echo "RUN NIGHTLY E2E......."
            ./hack/run-sonobouy-e2e.sh
        fi
        # Judge whether to change the compatibility case
        if [[ -n $DIFF_COMPATIBILE ]] ; then
            ## pr_ci debug stage, momentarily disable compatibility e2e
            echo "compatibility e2e..."
            #./hack/run-os-compatibility-e2e.sh "${CLUSTER_PREFIX}"-host $SPRAY_JOB_VERSION
        fi
    elif [ "${E2E_TYPE}" == "NIGHTLY" ]; then
        echo "RUN NIGHTLY E2E......."
        ./hack/run-sonobouy-e2e.sh
    else
        echo "RUN COMPATIBILITY E2E......."
        ./hack/run-os-compatibility-e2e.sh
    fi

fi

util::clean_online_kind_cluster