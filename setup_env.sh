#!/bin/bash

CLUSTER_CONFIGURATION_JSON="my_cluster_configurations.json"
if ! test -f "${CLUSTER_CONFIGURATION_JSON}"; then
    echo "$(date -u --rfc-3339=seconds) - ERROR: Failed to find the cluster configurations JSON file '${CLUSTER_CONFIGURATION_JSON}' in the current directory, abort. "
    exit 1
fi


# The Alibaba Cloud region, please make sure the region has at least 2 availability zones
AY_REGION=$(jq -r -c .region "${CLUSTER_CONFIGURATION_JSON}")
export AY_REGION

# The DNS base domain
AY_BASE_DOMAIN=$(jq -r -c .base_domain "${CLUSTER_CONFIGURATION_JSON}")
export AY_BASE_DOMAIN

# The cluster name prefix
AY_PREFIX=$(jq -r -c .cluster_name_prefix "${CLUSTER_CONFIGURATION_JSON}")
export AY_PREFIX

# The OpenShift version to be installed
AY_OCP_VERSION=$(jq -r -c .openshift_version "${CLUSTER_CONFIGURATION_JSON}")
export AY_OCP_VERSION

# The existing SSH public key file
SSH_PUBLIC_KEY_FILE=$(jq -r -c .ssh_public_key_file "${CLUSTER_CONFIGURATION_JSON}")
export SSH_PUBLIC_KEY_FILE
if ! test -f "${SSH_PUBLIC_KEY_FILE}"; then
    echo "$(date -u --rfc-3339=seconds) - ERROR: Failed to find the SSH public key file '${SSH_PUBLIC_KEY_FILE}', abort. "
    exit 1
fi

# The control-plane instance type
# For Single-Node cluster, at least 8 vCPUs and 32 GiB RAM (e.g. "ecs.g6.2xlarge")
CONTROL_PLANE_INSTANCE_TYPE=$(jq -r -c .control_plane_instance_type "${CLUSTER_CONFIGURATION_JSON}")
export CONTROL_PLANE_INSTANCE_TYPE

# The compute/worker instance type
COMPUTE_INSTANCE_TYPE=$(jq -r -c .compute_instance_type "${CLUSTER_CONFIGURATION_JSON}")
export COMPUTE_INSTANCE_TYPE

# CREATE_SNO_CLUSTER and CREATE_COMPACT_CLUSTER controls the cluster's size, 
# by default 3 control-plane machines and 3 compute/worker machines.
# Whether to create a Single-Node cluster
CREATE_SNO_CLUSTER=$(jq -r -c .create_sno_cluster "${CLUSTER_CONFIGURATION_JSON}")
export CREATE_SNO_CLUSTER

# Whether to create a 3-Node compact cluster
CREATE_COMPACT_CLUSTER=$(jq -r -c .create_compact_cluster "${CLUSTER_CONFIGURATION_JSON}")
export CREATE_COMPACT_CLUSTER

# Whether to create a bastoin host
CREATE_BASTION_HOST=$(jq -r -c .create_bastion_host "${CLUSTER_CONFIGURATION_JSON}")
export CREATE_BASTION_HOST

# The existing image ID for the bastion host
BASTION_HOST_IMAGE_ID=$(jq -r -c .bastion_host_image_id "${CLUSTER_CONFIGURATION_JSON}")
export BASTION_HOST_IMAGE_ID

# The existing SSH key pair to be used by the bastion host, because dynamically created 
# SSH key pair not working for bastion host, not sure why yet.
BASTION_HOST_SSH_KEY_PAIR=$(jq -r -c .bastion_host_ssh_key_pair "${CLUSTER_CONFIGURATION_JSON}")
export BASTION_HOST_SSH_KEY_PAIR

RESOURCE_GROUP_ID=$(jq -r -c .resource_group_id "${CLUSTER_CONFIGURATION_JSON}")
export RESOURCE_GROUP_ID