# Generate RHCOS Image
echo "Generating RHCOS Image"
mkdir -p /mnt/vm
cd /mnt/vm

export RHCOS_ISO="rhcos-live.x86_64.iso"
export RHCOS_ISO_URL="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/$RHCOS_ISO"

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