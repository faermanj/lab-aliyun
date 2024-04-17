#!/bin/bash
set -x
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# curlsh
# curl -sSL https://raw.githubusercontent.com/faermanj/lab-aliyun/main/ecs-init-installer.sh | bash


VERSION="0.0.1"

echo "=== OpenShift LabAY Install Script $VERSION ==="
echo "pwd: $(pwd)"
echo "whoami: $(whoami)"

echo "Installing openshift clients"

TMP="/tmp/labay"
INSTALL_DIR="$TMP/openshift-install/"

yum -y install unzip

mkdir -p $TMP
cd $TMP
curl -LOv https://github.com/faermanj/lab-aliyun/archive/refs/heads/main.zip

unzip main.zip
REPO_DIR="$TMP/lab-aliyun-main"
cd $REPO_DIR

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

mkdir -p "$INSTALL_DIR"

echo "Generate install config"
envsubst < $REPO_DIR/install-config.env.yaml > $INSTALL_DIR/install-config.yaml

echo "Generate manifests"
openshift-install create manifests --dir="$INSTALL_DIR"
# Step 2: Set the mastersSchedulable parameter in the /Installation_dir/manifests/cluster-scheduler-02-config.yml file to False to prevent pod scheduling on control plane machines.

echo "Generate ignition files"
openshift-install create ignition-configs --dir="$INSTALL_DIR"

echo "Install Dir"
find "$INSTALL_DIR"

echo "=== OpenShift LabAY Install Script Done $VERSION ==="
