#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
AY_REGION="eu-central-1"
AY_ZONE_A="eu-central-1a"
AY_ZONE_B="eu-central-1b"

AY_BUCKET_NAME="lab-ay-$AY_REGION"

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
AY_STACK_NAME="ay-${USER}-4"

aliyun ros CreateStack --region $AY_REGION \
    --StackName $AY_STACK_NAME \
    --Parameters.0.ParameterKey=RegionId \
    --Parameters.0.ParameterValue=$AY_REGION \
    --Parameters.1.ParameterKey=ZoneAId \
    --Parameters.1.ParameterValue=$AY_ZONE_A \
    --Parameters.2.ParameterKey=ZoneBId \
    --Parameters.2.ParameterValue=$AY_ZONE_B \
    --TemplateURL $AY_OBJECT_KEY | tee .ay-stack-create.out.log

if [ $? -eq 0 ]; then
    AY_STACK_ID=$(jq -r '.StackId' .ay-stack-create.log)
    echo "Stack [$AY_STACK_ID] created successfully."
    echo $AY_STACK_ID > .ay-stack-id.txt
    aliyun ros GetStack --region $AY_REGION \
    --StackId $AY_STACK_ID
else
    echo "Failed to create stack $AY_STACK_NAME."
fi


echo done
