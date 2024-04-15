#!/bin/bash
set -x
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Generate RHCOS Image
echo "Generating RHCOS Image"
export RHCOS_TMP="$DIR/.vm"
export RHCOS_ISO="rhcos-live.x86_64.iso"
export RHCOS_PATH="$RHCOS_TMP/$RHCOS_ISO"
export RHCOS_ISO_URL="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/$RHCOS_ISO"

mkdir -p "$RHCOS_TMP"

# check if iso path exists, download only if not
if [ ! -f "$RHCOS_PATH" ]; then
    curl -L -o "$RHCOS_PATH" "$RHCOS_ISO_URL"
fi

echo "Install system dependencies"
yum -y install qemu-img qemu-kvm libvirt libgcrypt-devel

echo "Start libvirtd"
sudo systemctl start libvirtd
# sleep 2
# sudo systemctl status libvirtd

echo "Clean existing files"
rm -r *.qcow2

echo "Create qcow2 disk files"
qemu-img create -f qcow2 $RHCOS_TMP/coreos-b.qcow2 30g
qemu-img create -f qcow2 $RHCOS_TMP/coreos-m.qcow2 30g
qemu-img create -f qcow2 $RHCOS_TMP/coreos-w.qcow2 30g

export QCOW_PATH="$RHCOS_TMP/coreos-b.qcow2"
export QCOW_NAME="coreos-b"
envsubst < qcow-config.env.xml > qcow-config.$QCOW_NAME.xml

echo "Creating bootstrap domain"
virsh create qcow-config.$QCOW_NAME.xml


