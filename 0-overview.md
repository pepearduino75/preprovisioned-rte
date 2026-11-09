# NKP Preprovisioned Deployment on vSphere

## Overview

This document summarizes the current workflow for deploying Nutanix Kubernetes Platform (NKP) on vSphere with preprovisioned Ubuntu virtual machines in an air-gapped environment.

## Deployment Workflow

1. **Create the Ubuntu template VM**

   Create an Ubuntu 24.04 LTS template VM in vSphere with the following configuration:

   - Create the `nutanix` user.
   - Configure DHCP.
   - Enable OpenSSH.
   - Allow the `nutanix` user to run `sudo` without a password.
   - Clean the VM before converting it into a template by removing logs, clearing the system journal, and resetting the hostname.

2. **Prepare variables file**

   Create a file with all variables required for the deployment, including the vSphere credentials, cluster name, and other configuration parameters.

3. **Create the control plane and worker VMs**

   Create the following VMs from the Ubuntu template:

   - Control plane nodes: `control-plane-01`, `control-plane-02`, and `control-plane-03`.
   - Worker nodes: `worker-node-01`, `worker-node-02`, `worker-node-03`, and `worker-node-04`.

   Configure the CPU, memory, and disk resources for each VM according to the NKP documentation.

4. **Prepare the bastion machine**

   Prepare the bastion machine and download the packages required to install NKP in an air-gapped environment, following the Nutanix documentation.

5. **Prepare the private registry**

   Configure the private registry, install or provide its certificate, and upload the packages required for an air-gapped NKP installation. Follow the Nutanix documentation for the registry requirements and package set.

6. **Create the machine configuration package**

   Create the package bundle to configure the machines

   **Important:** The `image-artifacts` directory is extracted from the `airgapped-bundle.tar.gz` archive downloaded from the Nutanix website. It contains the packages required to install NKP in an air-gapped environment.

7. **Upload the image artifacts**

   Upload the artifacts to the control plane and worker VMs:

8. **Create the bootstrap cluster**

   Create the bootstrap cluster required to provision the target NKP cluster.

9. **Create the cluster secret**

   Create the cluster secret in the `default` namespace.

10. **Prepare the preprovisioning inventory and cluster command**

   Prepare `preprovision_inventory.yaml` according to the Nutanix documentation and prepare the command used to create the cluster.

11. **Create the target cluster**

    Run the cluster creation command.

    **Important:** Do not use the `--selfmanaged` flag.

12. **Install the CSI driver**

    Install the CSI driver required for storage integration.

13. **Create the StorageClass**

    Create the storage class and make it the default.

14. **Create the CAPI drivers and pivot the resources**

    Create the Cluster API (CAPI) drivers and move the CAPI resources from the bootstrap cluster to the target cluster.

15. **Configure MetalLB**

    Create and apply the MetalLB configuration.

16. **Install Kommander**

    Install Kommander on the target NKP cluster.

## Repository Files

The repository includes scripts and manifests related to the workflow, including package creation, artifact upload, cluster creation, CAPI pivoting, MetalLB configuration, storage configuration, and Kommander installation.
