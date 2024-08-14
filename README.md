# OpenShift on Alibaba Cloud Lab

OpenShift can be deployed and operated in the Alibaba Cloud, leveraging the benefits of both a well-architected kubernetes platform and the services offered by the cloud provider. Learn more about the providers in their websites:
* [OpenShift](https://openshift.redhat.com/)
* [Alibaba Cloud](https://www.alibabacloud.com/en)

This repository offers a reference implementation for deploying [OpenShift](https://openshift.redhat.com/) clusters on [Alibaba Cloud](https://www.alibabacloud.com/en), using the [Assisted Installer](https://www.redhat.com/en/blog/how-to-use-the-openshift-assisted-installer) and it's [AI CLI](https://github.com/karmab/aicli). Here you'll find all the scripts and templates to get started and deploy you cluster. In the follwoing sections you'll find the information about how to configure and run this solution.

## Disclaimer

This repository is not maintained by Red Hat or AliBaba, it's an independent template solution built and shared by this repository colaborators.

## Cluster Deployment Guide

The following process, scripts and templates are our suggestion for installing a cluster.
You're expected to adapt to your scenario and configuration, as indicated in each step.

### Account Creation

Make sure you have access to the following services:
* [Red Hat Hybrid Console](https://console.redhat.com/)
* [Alibaba Cloud](https://www.alibabacloud.com/en)

### Workspace Creation

This repository is already configured for GitPod, so you can start a workspace with all tools pre-installed:
https://gitpod.io/#https://github.com/faermanj/lab-aliyun


Also, you're welcome to clone this repository and setup your own machine, the exact dependencies and commands can be found in the [gitpod Containerfile](https://github.com/faermanj/lab-aliyun/blob/main/.gitpod.Containerfile).


### Configure the Assited Installer CLI

#### Configure the Token
Obtain your Assisted Installer Offline Token at https://cloud.redhat.com/openshift/token and set as an environment variable named `AI_OFFLINETOKEN`
```bash
export AI_OFFLINETOKEN="YOUR_TOKEN"
```
You can also use dotfiles, [DirEnv](https://direnv.net) or your favorite mechanism to setup environment variables.

#### Configure the pull secret

Log in to the [OpenShift cluster manager portal](https://console.redhat.com/openshift/install/pull-secret) and download your pull secret to a file named ```openshift_pull.json```

#### Verify access to the Assisted Installer Service 

Try listing your clusters:
```bash
aicli list clusters
```


### Configure the Alibaba CLI

Setup authentication of Alibaba CLI as described in [Configure identity credentials](https://www.alibabacloud.com/help/en/cli/configure-credentials?spm=a2c63.p38356.0.0.10e94b35JWCLey)

Verify access to Alibaba services:
```bash
aliyun sts GetCallerIdentity
```

### Configure Alibaba Resources

The file `my_cluster_configurations.json` contains settings that are going to be used by the scripts.

*Review every setting according to your environment*

```
{
    "region": "us-east-1",
    "base_domain": "devcluster.mycompany.com",
    "cluster_name_prefix": "someone-",
    "openshift_version": "4.16.2",
    "ssh_public_key_file": "/home/gitpod/.ssh/id_rsa.pub",
    "control_plane_instance_type": "ecs.g6.xlarge",
    "compute_instance_type": "ecs.g6.large",
    "create_sno_cluster": false,
    "create_compact_cluster": false,
    "create_bastion_host": false,
    "bastion_host_image_id": "m-0xi1wndcxhwnxavcodzz",
    "bastion_host_ssh_key_pair": "openshift-dev",
    "resource_group_id": "rg-aek4mzon3le3dse"
}
```

Here's a brief description of each setting:
* region: Alibaba region where resources will be provisioned 
* base_domain: DNS zone name where cluster will be created
* cluster_name_prefix: Name prefix for the cluster and its resources
* openshift_version: Version of openshift to use
* ssh_public_key_file: Key file location for server access
* control_plane_instance_type: ECS instance type for control plane instances
* compute_instance_type: ECS instance type for worker nodes
* create_sno_cluster: Create a cluster with control plane and worker in a single node
* create_compact_cluster: Create a cluster with worker an control in the same nodes
* create_bastion_host: Create an extra instance outside of the cluster
* bastion_host_image_id: Image to be used for bastion host
* bastion_host_ssh_key_pair: Keypair name for bastion host
* resource_group_id: Alibaba Resource Manager group id

### Code Review

The scripts in this repository will provision the cluster, download and convert the image, provision the cloud resources and install the software.
The entrypoint is the `lab-aliyun.sh.aliyun` script, which invokes each other in turn.
The resources are created using Alibaba Resource Orchestration service (ROS), from the template `infra/ros/template.ros.yaml`.
You may want to change that template to include other services, or add that template to your own solution.

### Cluster Provisioning

The entrypoint script `lab-aliyun.sh.aliyun` can be executed and all steps should follow automatically.
In the end, your cluster will be installed and setup correctly.
The scripts create temporary files with logs, images and resource identities in the root of this repository, where it's exepected to execute.

### Troubleshooting
Although this code was tested and reviewed, there are quite some things that may go wrong, do check the logs and console for errors.

The first checkpoint is verifying that the stack is properly created in ROS. If the stack is rolled back, you'll find the reson in the events tab.

After that, cluster will be provisioned in the assisted installer service. You can verify the progress in the Red Hat Hybrid Cloud Console.

### Cleanup Resources

If you're no longer using the provisioned cluster, remember to delete the ROS stack and Openshift Cluster to avoid wasting resources.

### Send us your feedback and contributions!

Let us know if this reference implementation was helpful and how it could be improved.

