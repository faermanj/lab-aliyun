#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
AY_REGION="eu-central-1"
AY_STACK_NAME="ay-${USER}"

export ALIBABA_CLOUD_REGION_ID=$AY_REGION

aliyun ros DeleteStack --region $AY_REGION \
    --StackId $AY_STACK_ID 

echo done
