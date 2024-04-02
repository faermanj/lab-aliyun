#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
AY_REGION="eu-central-1"
AY_ZONE="eu-central-1a"
AY_BUCKET_NAME="lab-aliyun-$AY_REGION"

export ALIBABA_CLOUD_REGION_ID=$AY_REGION

# Check if the bucket exists
BUCKET_EXISTS=$(aliyun oss ls | grep $AY_BUCKET_NAME)

if [ -z "$BUCKET_EXISTS" ]; then
  echo "Bucket $AY_BUCKET_NAME does not exist. Creating..."
  # Create the bucket. Adjust the --acl (access control list) as per your requirement.
  aliyun oss mb oss://$AY_BUCKET_NAME --region $AY_REGION --acl public-read 
  if [ $? -eq 0 ]; then
    echo "Bucket $AY_BUCKET_NAME created successfully."
  else
    echo "Failed to create bucket $AY_BUCKET_NAME."
  fi
else
  echo "Bucket $AY_BUCKET_NAME already exists."
fi

# Upload ROS template to OSS bucket
AY_OBJECT_NAME="ros/template.ros.yaml"
AY_OBJECT_KEY="oss://$AY_BUCKET_NAME/$AY_OBJECT_NAME"
aliyun oss cp "$DIR/infra/ros/template.ros.yaml" $AY_OBJECT_KEY --region $AY_REGION --force
aliyun oss set-acl $AY_OBJECT_KEY public-read --region $AY_REGION

AY_TEMPLATE_URL="https://$AY_BUCKET_NAME.oss-$AY_REGION.aliyuncs.com/$AY_OBJECT_NAME"
AY_STACK_NAME="ay-${USER}1"

aliyun ros CreateStack --region $AY_REGION \
    --StackName $AY_STACK_NAME \
    --Parameters.0.ParameterKey=RegionId \
    --Parameters.0.ParameterValue=$AY_REGION \
    --Parameters.1.ParameterKey=ZoneId \
    --Parameters.1.ParameterValue=$AY_ZONE \
    --TemplateURL $AY_OBJECT_KEY | tee .ay-stack-create.log

AY_STACK_ID=$(jq -r '.StackId' .ay-stack-create.log)
aliyun ros GetStack --region $AY_REGION \
    --StackId $AY_STACK_ID

echo done
