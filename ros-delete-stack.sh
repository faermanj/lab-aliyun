#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
AY_REGION="eu-central-1"
AY_STACK_NAME="ay-${USER}-2"

export ALIBABA_CLOUD_REGION_ID=$AY_REGION

AY_STACK_ID=$(jq -r '.StackId' .ay-stack-create.log)
echo "Updating stack $AY_STACK_ID with template $AY_OBJECT_KEY"

aliyun ros DeleteStack --region $AY_REGION \
    --StackId $AY_STACK_ID | tee ros-delete-stack.log

echo done
