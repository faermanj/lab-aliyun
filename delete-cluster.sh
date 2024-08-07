#!/bin/bash

CLUSTER_CONFIGURATION_JSON="my_cluster_configurations.json"
if ! test -f "${CLUSTER_CONFIGURATION_JSON}"; then
    echo "$(date -u --rfc-3339=seconds) - ERROR: Failed to find the cluster configurations JSON file '${CLUSTER_CONFIGURATION_JSON}' in the current directory, abort. "
    exit 1
fi

AY_REGION=$(jq -r -c .region "${CLUSTER_CONFIGURATION_JSON}")
AY_STACK_NAME=$(cat ".ay-cluster-name")
AY_STACK_ID=$(jq -r '.StackId' .ay-stack-create.json)
CLUSTER_ID=$(cat ".ay-cluster-id")
AY_BUCKET_NAME=$(cat ".ay-oss-bucket-name")
ECS_IMAGE_ID=$(jq -r '.ImageId' .import-image.log.json)

function run_command() {
    local -r cmd="$1"
    echo -e "\n$(date -u --rfc-3339=seconds) - Running Command: ${cmd}"
    eval "${cmd}"
}


echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (1/4) Deleting the cluster..."
cmd="aicli delete cluster ${CLUSTER_ID} -y"
run_command "${cmd}"

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (2/4) Deleting the stack ${AY_STACK_NAME}..."
cmd="aliyun ros DeleteStack --region $AY_REGION --StackId $AY_STACK_ID | tee .ros-delete-stack.log"
run_command "${cmd}"
while true; do
  AY_STACK_STATUS=$(aliyun ros GetStack --region $AY_REGION --StackId $AY_STACK_ID | jq -r '.Status')
  if [[ "$AY_STACK_STATUS" == "DELETE_COMPLETE" ]]; then
    echo "$(date -u --rfc-3339=seconds) - INFO: Stack $AY_STACK_NAME deleted successfully."
    break
  else
    echo "$(date -u --rfc-3339=seconds) - INFO: Stack $AY_STACK_NAME status: $AY_STACK_STATUS"
    sleep 30
  fi
done

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (3/4) Deleting the OSS bucket..."
cmd="aliyun oss rm oss://${AY_BUCKET_NAME}/${AY_STACK_NAME}.qcow2 -f"
run_command "${cmd}"
cmd="aliyun oss rm oss://${AY_BUCKET_NAME}/ros/template.ros.yaml -f"
run_command "${cmd}"
cmd="aliyun oss rm oss://${AY_BUCKET_NAME}  -f --bucket "
run_command "${cmd}"

echo -e "\n$(date -u --rfc-3339=seconds) - INFO: (4/4) Deleting the ECS image..."
aliyun_ecs_endpoint=$(aliyun ecs DescribeRegions | jq -c ".Regions.Region[] | select(.RegionId | contains(\"${AY_REGION}\"))" | jq -r .RegionEndpoint)
cmd="aliyun ecs DeleteImage --region=${AY_REGION} --endpoint=${aliyun_ecs_endpoint} --ImageId=${ECS_IMAGE_ID}"
run_command "${cmd}"

echo "Done."
