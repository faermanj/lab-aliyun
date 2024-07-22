#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

# The maximum seconds to wait for the cluster turns "ready" (to start installation)
CLUSTER_READY_TIMEOUT=1200

# The number of cluster machines
HOSTS_COUNT=6
if [[ "${CREATE_SNO_CLUSTER}" == "true" ]]; then
    HOSTS_COUNT=1
elif [[ "${CREATE_COMPACT_CLUSTER}" == "true" ]]; then
    HOSTS_COUNT=3
fi
# The temporary JSON file to save the ECS instances of the cluster
ECS_INSTANCES_JSON=$(mktemp)

# The host name of the instance under question
instance_name=""

# Temporary output file
tmp_out=$(mktemp)

# The return/exit code
ret=0


function run_command() {
    local -r cmd="$1"
    echo -e "\n$(date -u --rfc-3339=seconds) - Running Command: ${cmd}"
    eval "${cmd}"
}

function find_instance_by_ip() {
    local -r ip_address="$1"

    local aliyun_ecs_endpoint=$(aliyun ecs DescribeRegions | jq -c ".Regions.Region[] | select(.RegionId | contains(\"${AY_REGION}\"))" | jq -r .RegionEndpoint)

    if [ ! -s "${ECS_INSTANCES_JSON}" ]; then
        aliyun ecs DescribeInstances --RegionId "${AY_REGION}" --endpoint "${aliyun_ecs_endpoint}" > "${ECS_INSTANCES_JSON}"
    fi

    instance_name=$(cat "${ECS_INSTANCES_JSON}" | jq -c ".Instances.Instance[] | select(.NetworkInterfaces.NetworkInterface[].PrimaryIpAddress | contains(\"${ip_address}\"))" | jq -r .InstanceName)
}

function list_cluster() {
    cmd="aicli list cluster"
    run_command "${cmd}"
    cmd="aicli list host"
    run_command "${cmd}"
}

function exit_on_error() {
    local -r error_msg="$1"

    if [ $ret -ne 0 ]; then
        echo "$(date -u --rfc-3339=seconds) - ERROR: ${error_msg}, abort."
        exit $ret
    fi
}


echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (1/8) Wait for up to ${CLUSTER_READY_TIMEOUT} seconds for the cluster ready for installation..."
t0=$(date +%s)
while true; do
    cmd="aicli list cluster | tee ${tmp_out}"
    run_command "${cmd}"
    cluster_name=$(grep " ${AY_CLUSTER_NAME} " "${tmp_out}" | awk '{print $2}')
    cluster_id=$(grep " ${AY_CLUSTER_NAME} " "${tmp_out}" | awk '{print $4}')
    cluster_status=$(grep " ${AY_CLUSTER_NAME} " "${tmp_out}" | awk '{print $6}')
    cluster_dns_domain=$(grep " ${AY_CLUSTER_NAME} " "${tmp_out}" | awk '{print $8}')
    echo "$(date -u --rfc-3339=seconds) - DEBUG: cluster_name: ${cluster_name}, cluster_id: ${cluster_id}, cluster_status: ${cluster_status}, cluster_dns_domain: ${cluster_dns_domain}"

    if [[ "${cluster_status}" == "ready" ]] || [[ "${cluster_status}" == "pending-for-input" ]]; then
        echo "$(date -u --rfc-3339=seconds) - INFO: Cluster is ready for installation."
        break
    else
        echo "$(date -u --rfc-3339=seconds) - INFO: Cluster '${AY_CLUSTER_NAME}' not found or not ready yet."
    fi

    sleep 30
    t1=$(date +%s)
    if [ $(($t1 - $t0)) -ge ${CLUSTER_READY_TIMEOUT} ]; then
        echo "$(date -u --rfc-3339=seconds) - ERROR: Already waited for ${CLUSTER_READY_TIMEOUT} seconds, but the cluster is still not ready, abort."
        ret=1
        break
    fi
done
exit_on_error "(1/8) timed out on waiting for cluster ready/pending-for-input"
export CLUSTER_ID=${cluster_id}
echo $CLUSTER_ID > .ay-cluster-id

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (2/8) Update hosts' names and roles..."
while true; do
    cmd="aicli list host | tee ${tmp_out}"
    run_command "${cmd}"
    readarray -t hosts < <(grep "${AY_CLUSTER_NAME}" "${tmp_out}")
    if [[ ${#hosts[@]} -ne ${HOSTS_COUNT} ]]; then
        echo "$(date -u --rfc-3339=seconds) - INFO: Some hosts not discovered yet. "
        sleep 10
        continue
    fi
    if grep "${AY_CLUSTER_NAME}" "${tmp_out}" | grep "discovering"; then
        echo "$(date -u --rfc-3339=seconds) - INFO: Some hosts not finish discovering. "
        sleep 10
        continue
    fi
    break
done
updated=0
for line in "${hosts[@]}"; do
    name=$(echo "${line}" | awk '{print $2}')
    ip=$(echo "${line}" | awk '{print $14}')
    find_instance_by_ip "${ip}"
    cmd="aicli update host ${name} -P name=${instance_name}"
    if [[ ${HOSTS_COUNT} -gt 3 ]]; then
        # only assign roles if the cluster is not SNO or compact cluster
        if [[ "${instance_name}" =~ master ]]; then
            cmd="${cmd} -P role=master"
        else
            cmd="${cmd} -P role=worker"
        fi
    fi
    run_command "${cmd}"
    echo "$(date -u --rfc-3339=seconds) - INFO: Updated for host '${instance_name}' (${ip})"
    updated=$(( $updated + 1 ))
done
echo "$(date -u --rfc-3339=seconds) - INFO: Updated all ${updated} hosts."
cmd="aicli list host | grep ${AY_CLUSTER_NAME}"
run_command "${cmd}"

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (3/8) Custom cluster networking and then wait for it ready..."
while true; do
    echo "$(date -u --rfc-3339=seconds) - Running Command: aicli update cluster ${CLUSTER_ID} -P user_managed_networking=true"
    aicli update cluster ${CLUSTER_ID} -P user_managed_networking=true || echo "ignore the error"
    if aicli info cluster "${CLUSTER_ID}" | grep 'user_managed_networking: True'; then
        echo "$(date -u --rfc-3339=seconds) - INFO: Successfully set 'user_managed_networking: True' for the cluster. "
        break
    fi
    sleep 10
done
t0=$(date +%s)
while true; do
    cmd="aicli list cluster | grep ${AY_CLUSTER_NAME} | tee ${tmp_out}"
    run_command "${cmd}"
    if grep -qvE "insufficient|pending-for-input" "${tmp_out}"; then
        cmd="aicli list host | grep ${AY_CLUSTER_NAME} | tee ${tmp_out}"
        run_command "${cmd}"
        if grep -qvE "insufficient|pending-for-input" "${tmp_out}"; then
            echo "$(date -u --rfc-3339=seconds) - INFO: Cluster and hosts are ready for installation."
            break
        fi
    fi

    sleep 30
    t1=$(date +%s)
    if [ $(($t1 - $t0)) -ge ${CLUSTER_READY_TIMEOUT} ]; then
        echo "$(date -u --rfc-3339=seconds) - ERROR: Already waited for ${CLUSTER_READY_TIMEOUT} seconds, but the cluster is still not ready, abort."
        ret=1
        break
    fi
done
exit_on_error "(3/8) timed out on waiting for cluster ready/pending-for-input"

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (4/8) Start cluster installation..."
cmd="aicli start cluster ${CLUSTER_ID}"
run_command "${cmd}"
sleep 30

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (5/8) Wait for cluster install-complete..."
list_cluster
echo -e "\n$(date -u --rfc-3339=seconds) - Running Command: aicli wait cluster ${CLUSTER_ID}"
aicli wait cluster "${CLUSTER_ID}"

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (6/8) Cluster installation complete, check the cluster info..."
list_cluster
cmd="aicli info cluster ${CLUSTER_ID}"
run_command "${cmd}"

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (7/8) Downloading the kubeconfig for cluster health check..."
aicli download kubeconfig "${CLUSTER_ID}"
mv "./kubeconfig.${CLUSTER_ID}" /tmp/kubeconfig
echo "$(date -u --rfc-3339=seconds) - INFO: Cluster's kubeconfig is saved as '/tmp/kubeconfig'."

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (8/8) TODO: Cluster health check..."
# TODO: cluster health check

rm -f "${ECS_INSTANCES_JSON}" "${tmp_out}"
exit $ret