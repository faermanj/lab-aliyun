#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TMP="$DIR/tmp"

RHCOS_ISO="rhcos-4.15.0-x86_64-live.x86_64.iso"
RHCOS_ISO_URL="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/$RHCOS_ISO"

# Check dependencies
# Check if yum is available (commonly available in Fedora)
if command -v yum &> /dev/null; then
    echo "Fedora system detected. Installing packages with yum..."
    sudo yum -y install qemu-img qemu-kvm libvirt libgcrypt-devel

# Check if apt is available (commonly available in Ubuntu)
elif command -v apt &> /dev/null; then
    echo "Ubuntu system detected. Installing packages with apt..."
    sudo apt update
    sudo apt install -y qemu-utils qemu-kvm libvirt-daemon-system libvirt-clients libgcrypt20-dev

else
    echo "Unsupported system. Exiting..."
    exit 1
fi

# Download RHCOS ISO
mkdir -p $TMP
curl -L -o $TMP/$RHCOS_ISO  $RHCOS_ISO_URL
ls $TMP

# Start libvirt service
systemctl start libvirtd