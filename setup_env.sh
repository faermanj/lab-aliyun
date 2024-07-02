#!/bin/bash

# Provide the cluster configurations by setting up the global variables here for now. 

# The Alibaba Cloud region, please make sure the region has at least 2 availability zones
export AY_REGION="us-east-1"
# The DNS base domain
export AY_BASE_DOMAIN="alicloud-qe.devcluster.openshift.com"
# The cluster name prefix
export AY_PREFIX="jiwei-ali-"
# The OpenShift version to be installed
export AY_OCP_VERSION="4.16.0"

# The existing SSH public key file
export SSH_PUBLIC_KEY_FILE="/root/jiwei/openshift-qe.pub"

# Below 2 parameters controls the cluster's size, by default 3 control-plane machines and 3 compute/worker machines. 
# Whether to create a Single-Node cluster
export CREATE_SNO_CLUSTER="false"
# Whether to create a 3-Node compact cluster
export CREATE_COMPACT_CLUSTER="true"

# The control-plane instance type
# For Single-Node cluster, at least 8 vCPUs and 32 GiB RAM (e.g. "ecs.g6.2xlarge")
export CONTROL_PLANE_INSTANCE_TYPE="ecs.g6.xlarge"
# The compute/worker instance type
export COMPUTE_INSTANCE_TYPE="ecs.g6.large"

# Whether to create a bastoin host
export CREATE_BASTION_HOST="false"
# The existing image ID for the bastion host
#export BASTION_HOST_IMAGE_ID="centos_stream_9_uefi_x64_20G_alibase_20240117.vhd"
export BASTION_HOST_IMAGE_ID="m-0xi1wndcxhwnxavcodyj"
# The existing SSH key pair to be used by the bastion host, because dynamically created 
# SSH key pair not working for bastion host, not sure why yet.
export BASTION_HOST_SSH_KEY_PAIR="openshift-qe"
