# docker build --no-cache --progress=plain -f .gitpod.Dockerfile .
FROM gitpod/workspace-full

# System
RUN bash -c "sudo apt-get update"
RUN bash -c "sudo install-packages direnv gettext mysql-client gnupg golang qemu-utils"
RUN bash -c "sudo pip install --upgrade pip"

# Jupyter
RUN bash -c "pip install jupyter"

# Aliyun CLI
RUN bash -c "brew install aliyun-cli"

# OpenShift Installer
RUN bash -c "mkdir -p '/tmp/openshift-installer' \
    && wget -nv -O '/tmp/openshift-installer/openshift-install-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-install-linux.tar.gz' \
    && tar zxvf '/tmp/openshift-installer/openshift-install-linux.tar.gz' -C '/tmp/openshift-installer' \
    && sudo mv  '/tmp/openshift-installer/openshift-install' '/usr/local/bin/' \
    && rm '/tmp/openshift-installer/openshift-install-linux.tar.gz' \
    && openshift-install version \
    "
    
# Credentials Operator CLI
RUN bash -c "mkdir -p '/tmp/ccoctl' \
    && wget -nv -O '/tmp/ccoctl/ccoctl-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/ccoctl-linux.tar.gz' \
    && tar zxvf '/tmp/ccoctl/ccoctl-linux.tar.gz' -C '/tmp/ccoctl' \
    && sudo mv '/tmp/ccoctl/ccoctl' '/usr/local/bin/' \
    && rm '/tmp/ccoctl/ccoctl-linux.tar.gz'\
    "

# OpenShift CLI
RUN bash -c "mkdir -p '/tmp/oc' \
    && wget -nv -O '/tmp/oc/openshift-client-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-client-linux.tar.gz' \
    && tar zxvf '/tmp/oc/openshift-client-linux.tar.gz' -C '/tmp/oc' \
    && sudo mv '/tmp/oc/oc' '/usr/local/bin/' \
    && sudo mv '/tmp/oc/kubectl' '/usr/local/bin/' \
    && rm '/tmp/oc/openshift-client-linux.tar.gz' \
    "

RUN bash -c "pip3 install aicli"

