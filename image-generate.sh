#!/bin/bash
export SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export REPO_DIR=$(dirname $SCRIPTS_DIR)
# General AliBaba settings
AY_REGION=${AY_REGION:-"eu-central-1"} 
AY_BUCKET_NAME=${AY_BUCKET_NAME:-"lab-ay-$AY_REGION"}

# Files that should exist
AY_BOOTSTRAP_URL="https://$AY_BUCKET_NAME.oss-$AY_REGION.aliyuncs.com/bootstrap.ign"
AY_MASTER_URL="https://$AY_BUCKET_NAME.oss-$AY_REGION.aliyuncs.com/master.ign"
AY_WORKER_URL="https://$AY_BUCKET_NAME.oss-$AY_REGION.aliyuncs.com/worker.ign"

# Generate RHCOS Image
echo "Generating RHCOS Image"
export RHCOS_TMP="$DIR/.vm"
export RHCOS_DIST="$DIR/dist"
export RHCOS_ISO="rhcos-live.x86_64.iso"
export RHCOS_PATH="$RHCOS_TMP/$RHCOS_ISO"
export RHCOS_ISO_URL="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/$RHCOS_ISO"

mkdir -p "$RHCOS_TMP"
mkdir -p "$RHCOS_DIST"

# check if iso path exists, download only if not
if [ ! -f "$RHCOS_PATH" ]; then
    curl -L -o "$RHCOS_PATH" "$RHCOS_ISO_URL"
fi

echo "Install system dependencies"
yum -y install qemu-img qemu-kvm libvirt libgcrypt-devel coreos-installer

echo "Start libvirtd"
sudo systemctl start libvirtd
# sleep 2
# sudo systemctl status libvirtd

echo "Clean existing files"
rm -rf $REPO_DIR/.vm/*.qcow2
rm -rf $REPO_DIR/dist/*.qcow2


echo "Create qcow2 disk files"

export QCOW_NAME="coreos-b"
echo "Creating image $QCOW_NAME"
export QCOW_IMG="$RHCOS_DIST/$QCOW_NAME.qcow2"
export QCOW_CONFIG="qcow-config.$QCOW_NAME.xml"
export QCOW_PATH="$QCOW_IMG"

qemu-img create -f qcow2 $QCOW_IMG 30g
sleep 10
envsubst < qcow-config.env.xml > $QCOW_CONFIG
sleep 10
echo virsh create $QCOW_CONFIG
echo virsh
vir domifaddr $QCOW_NAME
echo virsh dumpxml $QCOW_NAME
echo sudo coreos-installer install /dev/vda --ignition-url $AY_BOOTSTRAP_URL



