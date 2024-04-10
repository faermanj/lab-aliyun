# curl -sSL https://raw.githubusercontent.com/faermanj/lab-aliyun/main/ecs-init-installer.sh | bash
#!/bin/bash
set -x

VERSION="0.0.1"

echo "=== OpenShift LabAY Install Script $VERSION ==="
echo "pwd: $(pwd)"
echo "whoami: $(whoami)"

echo "Installing openshift clients"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TMP="/tmp/labay"

yum -y install unzip

mkdir -p $TMP
cd $TMP
curl -LOv https://github.com/faermanj/lab-aliyun/archive/refs/heads/main.zip

unzip main.zip
cd lab-aliyun-main

echo "Installing openshift clients"

# OpenShift Installer
mkdir -p '/tmp/openshift-installer' 
wget -nv -O '/tmp/openshift-installer/openshift-install-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-install-linux.tar.gz' 
tar zxvf '/tmp/openshift-installer/openshift-install-linux.tar.gz' -C '/tmp/openshift-installer' 
sudo mv  '/tmp/openshift-installer/openshift-install' '/usr/local/bin/' 
rm '/tmp/openshift-installer/openshift-install-linux.tar.gz' 
openshift-install version 
    
# Credentials Operator CLI
mkdir -p '/tmp/ccoctl' 
wget -nv -O '/tmp/ccoctl/ccoctl-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/ccoctl-linux.tar.gz' 
tar zxvf '/tmp/ccoctl/ccoctl-linux.tar.gz' -C '/tmp/ccoctl' 
sudo mv '/tmp/ccoctl/ccoctl' '/usr/local/bin/' 
rm '/tmp/ccoctl/ccoctl-linux.tar.gz'

# OpenShift CLI
mkdir -p '/tmp/oc' 
wget -nv -O '/tmp/oc/openshift-client-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-client-linux.tar.gz' 
tar zxvf '/tmp/oc/openshift-client-linux.tar.gz' -C '/tmp/oc' 
sudo mv '/tmp/oc/oc' '/usr/local/bin/' 
sudo mv '/tmp/oc/kubectl' '/usr/local/bin/' 
rm '/tmp/oc/openshift-client-linux.tar.gz' 
oc version client

# Generate RHCOS Image
echo "Generating RHCOS Image"
mkdir -p /mnt/vm
cd /mnt/vm

RHCOS_ISO="rhcos-live.x86_64.iso"
RHCOS_ISO_URL="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/$RHCOS_ISO"

curl -LOv $RHCOS_ISO_URL

echo "Install system dependencies"
yum -y install qemu-img qemu-kvm libvirt libgcrypt-devel

echo "Start libvirtd"
systemctl start libvirtd

echo "Create qcow2 disk files"
qemu-img create -f qcow2 coreos-b.qcow2 30g
qemu-img create -f qcow2 coreos-m.qcow2 30g
qemu-img create -f qcow2 coreos-w.qcow2 30g

export RHCOS_ISO_PATH="/mnt/vm/$RHCOS_ISO"
export QCOW_PATH="/mnt/vm/coreos-b.qcow2"
export QCOW_NAME="coreos-b"
envsubst < qcow-config.env.xml > qcow-config.$QCOW_NAME.xml


echo "=== OpenShift LabAY Install Script Done $VERSION ==="
