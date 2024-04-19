#!/bin/bash
set -ex

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(dirname $SCRIPT_DIR)
# curlsh
# curl -sSL https://raw.githubusercontent.com/faermanj/lab-aliyun/main/ecs-init-install.sh | bash


VERSION="0.0.1"
AY_REGION=${AY_REGION:-"eu-central-1"} 
AY_PREFIX=${AY_PREFIX:-"labay"}
AY_BUCKET_NAME=${AY_BUCKET_NAME:-"$AY_PREFIX-$AY_REGION"}
AY_CLUSTER_NAME=${AY_CLUSTER_NAME:-"$AY_PREFIX$(date +%Y%m%d%H%M)"}

echo "=== OpenShift LabAY Install Script $VERSION ==="
echo "pwd: $(pwd)"
echo "whoami: $(whoami)"
echo "cluster: $AY_CLUSTER_NAME"
echo "region: $AY_REGION"
echo "bucket: $AY_BUCKET_NAME"


echo "Installing openshift clients"

TMP_DIR="$SCRIPT_DIR/.tmp"
INSTALL_DIR="$SCRIPT_DIR/.openshift"

mkdir -p $TMP_DIR
cd $TMP_DIR

# remote exec
# REPO_ZIP=https://github.com/faermanj/lab-aliyun/archive/refs/heads/main.zip
# curl -LOv $REPO_ZIP | unzip -o
# REPO_DIR="$TMP_DIR/lab-aliyun-main"

# local exec
REPO_DIR="$SCRIPT_DIR"

cd $REPO_DIR

echo "Installing openshift clients"

# OpenShift Install
# check if openshift-install exists
if ! command -v openshift-install &> /dev/null
then
    mkdir -p "$TMP_DIR/openshift-install" 
    wget -nv -O "$TMP_DIR/openshift-install/openshift-install-linux.tar.gz" "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-install-linux.tar.gz" 
    tar zxvf "$TMP_DIR/openshift-install/openshift-install-linux.tar.gz" -C "$TMP_DIR/openshift-install" 
    sudo mv  "$TMP_DIR/openshift-install/openshift-install" "/usr/local/bin/" 
    rm "$TMP_DIR/openshift-install/openshift-install-linux.tar.gz" 
fi
openshift-install version 

    
# Credentials Operator CLI
if ! command -v ccoctl &> /dev/null
then
    mkdir -p "$TMP_DIR/ccoctl" 
    wget -nv -O "$TMP_DIR/ccoctl/ccoctl-linux.tar.gz" "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/ccoctl-linux.tar.gz" 
    tar zxvf "$TMP_DIR/ccoctl/ccoctl-linux.tar.gz" -C "$TMP_DIR/ccoctl" 
    sudo mv "$TMP_DIR/ccoctl/ccoctl" "/usr/local/bin/" 
    rm "$TMP_DIR/ccoctl/ccoctl-linux.tar.gz"
fi

# OpenShift CLI
if ! command -v oc &> /dev/null
then
    mkdir -p "$TMP_DIR/oc" 
    wget -nv -O "$TMP_DIR/oc/openshift-client-linux.tar.gz" "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-client-linux.tar.gz" 
    tar zxvf "$TMP_DIR/oc/openshift-client-linux.tar.gz" -C "$TMP_DIR/oc" 
    sudo mv "$TMP_DIR/oc/oc" "/usr/local/bin/" 
    sudo mv "$TMP_DIR/oc/kubectl" "/usr/local/bin/" 
    rm "$TMP_DIR/oc/openshift-client-linux.tar.gz" 
    oc version client
fi

mkdir -p "$INSTALL_DIR"

# Create alibaba oss bucket usiing aliyun cli
# check if bucket exists, create if not
if ! aliyun oss ls | grep -q $AY_BUCKET_NAME
then
    echo "Create alibaba oss bucket"
    aliyun oss mb oss://$AY_BUCKET_NAME --region $AY_REGION
fi

## Assisted Installer Section ##
export AY_OCP_VERSION="4.14"
export AY_MANIFESTS_DIR="$SRC_DIR/.ai/manifests"
mkdir -p "$AY_MANIFESTS_DIR"

echo aicli create cluster "$AY_CLUSTER_NAME" \
    -P openshift_version="$AY_OCP_VERSION" \
    -P base_dns_domain="$AY_BASE_DOMAIN" 

sleep 10 

# check if iso does not exist
export AY_ISO_FILE="${AY_CLUSTER_NAME}.iso"

if ! aliyun oss ls | grep -q $AY_ISO_FILE
then
    aicli create cluster "$AY_CLUSTER_NAME" \
        -P openshift_version="$AY_OCP_VERSION" \
        -P base_dns_domain="$AY_BASE_DOMAIN" 
    echo "Download iso from assisted installer"
    aicli download iso "$AY_CLUSTER_NAME"
    qemu-img convert -O qcow2 ${AY_CLUSTER_NAME}.iso ${AY_CLUSTER_NAME}.qcow2
fi


export AY_OBJECT_NAME="${AY_CLUSTER_NAME}.qcow2"
# du -sh --block-size=M labay202404191718.qcow2
export AY_OBJECT_SIZE=$(du -sh --block-size=M $AY_OBJECT_NAME)

echo "Upload qcow2 to alibaba oss"
aliyun oss cp $AY_OBJECT_NAME oss://$AY_BUCKET_NAME/

echo "Verify image upload"
export AY_QCOW_URL="oss://$AY_BUCKET_NAME/$AY_OBJECT_NAME"
aliyun oss ls $AY_QCOW_URL

#create alibaba custom image from qcow 
echo "Create alibaba custom image from qcow"
export AY_IMAGE_NAME="${AY_CLUSTER_NAME}-image"

# https://www.alibabacloud.com/help/en/ecs/developer-reference/api-ecs-2014-05-26-importimage?spm=a2c63.p38356.0.0.7c4a2122Z0bC7W
echo aliyun ecs ImportImage \
    --RegionId $AY_REGION \
    --ImageName $AY_IMAGE_NAME \
    --Architecture x86_64 \
    --Platform CoreOS \
    --Description "OpenShift Image for ${AY_CLUSTER_NAME}" \
    --DiskDeviceMapping.1.OSSBucket $AY_BUCKET_NAME \
    --DiskDeviceMapping.1.OSSObject $AY_OBJECT_NAME \
    --DiskDeviceMapping.1.DiskImageSize $AY_OBJECT_SIZE \
#    | tee .create-image.log.json

export AY_IMAGE_ID=$(jq -r '.ImageId' .create-image.log.json)
echo "export AY_IMAGE_ID=$AY_IMAGE_ID"

echo "=== OpenShift LabAY Install Script Done $VERSION ==="
