# Prepare a vSphere Template for NKP

This procedure prepares an Ubuntu 24.04 LTS virtual machine as a vSphere template for Nutanix Kubernetes Platform (NKP) deployments.

The steps are grouped by the machine on which they must be performed:

1. [vCenter](#1-vcenter)
2. [Ubuntu template VM](#2-ubuntu-template-vm)
3. [Bastion or jump host](#3-bastion-or-jump-host)
4. [Final preparation on the template VM](#4-final-preparation-on-the-template-vm)
5. [Snapshot and template conversion in vCenter](#5-snapshot-and-template-conversion-in-vcenter)
6. [Create the NKP image from the bastion host](#6-create-the-nkp-image-from-the-bastion-host)

## 1. vCenter

**Connect to vCenter before starting this section.** Use the vCenter web interface with an account that can create, configure, snapshot, and convert virtual machines into templates.

### 1.1 Download the operating system image

Download the operating system image that will be used as the base for the template and upload it to the vSphere Content Library.

Ubuntu 24.04 LTS is recommended because NAI will be installed later and requires compatibility with NVIDIA drivers.

### 1.2 Create the template VM

Create virtual machine template from the Ubuntu image with the following configuration (edit resources onec they are created from template):

- Minimum resources: 2 vCPUs, 8 GB RAM, and a 20 GB disk.
- Network adapter connected to the target VLAN.
- Network configuration set to DHCP. A static IP could be an option if customer doesn't have DHCP on VLAN.
- SSH server installed and enabled.
- An administrative user, `nutanix` in this case, with `sudo` privileges.
- `open-vm-tools` recommended.

Record the VM IP addresses. You will declare them on variable file.

## 2. Configurations on template VM

**Connect to the Ubuntu template VM before starting this section.** Connect through the vSphere console or SSH using the administrative account created during VM provisioning.

### 2.1 Configure the `nutanix` sudo policy

Create a passwordless sudo policy for the `nutanix` user:

```bash
sudo visudo -f /etc/sudoers.d/nutanix
```

Add the following line, then save and close the file:

```text
nutanix ALL=(ALL) NOPASSWD: ALL
```

### 2.2 Prepare the `nutanix` SSH directory

Create the directory that will receive the public key from the bastion host:

```bash
sudo install -d -m 700 -o nutanix -g nutanix /home/nutanix/.ssh
```

### 2.3 Configure Generic DHCP Networking (optional)

Identify the name of the primary network interface:

```bash
IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')
echo "Detected interface: ${IFACE}"
```

Back up the current configuration:

```bash
sudo mkdir -p /root/netplan-backup
sudo cp -a /etc/netplan/. /root/netplan-backup/
```

If the VM has a static configuration created by the installer, replace it with DHCP:

```bash
sudo rm -f /etc/netplan/*.yaml

sudo tee /etc/netplan/99-nkp-dhcp.yaml >/dev/null <<EOF
network:
  version: 2
  ethernets:
    ${IFACE}:
      dhcp4: true
      dhcp6: false
EOF

sudo chmod 600 /etc/netplan/99-nkp-dhcp.yaml
sudo netplan generate
```

If you are connected over SSH, apply the change from the vSphere console to avoid losing the session:

```bash
sudo netplan apply
```

Validate the configuration:

```bash
ip -br address
ip route
resolvectl status
```

### 2.4 Provide Permissions to Nutanix User for NKP Image Creation

provide permissions to Ubuntu server to enable the nkp create package to run the image creation command. Only for preprovisioned:

```bash
U=nutanix
echo "${U} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/90-${U}" >/dev/null
sudo chmod 0440 "/etc/sudoers.d/90-${U}"
sudo visudo -cf "/etc/sudoers.d/90-${U}"
```

### 2.5 Disable Swap

NKP nodes must not use swap. Disable it in the template:

```bash
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^/#/' /etc/fstab
sudo swapon --show
```

The last command should not return any active devices.

### 2.6 Copy the public key to the template VM

Follow the below section to accomplish the copy of the public key to the template VM.

## 3. Bastion or Jump Host

**Connect to the bastion or jump host before starting this section.** Use the account that will run the NKP image-creation command. The examples below assume the user is `mansolo` and that the private key is stored in `/home/mansolo/.ssh/`.

### 3.1 Generate an SSH key pair

Create the key pair that will be used to access the template and the bastion host:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

ssh-keygen -t rsa -b 4096 -m PEM \
  -f ~/.ssh/nkp-bastion \
  -C "nkp-bastion"
```

### 3.2 Copy the public key to the template VM

From the bastion host, copy the public key to the template VM:

```bash
scp /home/mansolo/.ssh/nkp-bastion.pub \
  nutanix@10.68.200.13:/home/nutanix/.ssh/authorized_keys
```

### 3.3 Set the key permissions remotely

Run the following command from the bastion host:

```bash
ssh -i ~/.ssh/nkp-bastion nutanix@10.68.200.13 \
  'sudo chown nutanix:nutanix /home/nutanix/.ssh/authorized_keys && \
   sudo chmod 600 /home/nutanix/.ssh/authorized_keys'
```

### 3.4 Validate Key-Based Access to the Template VM

Validate passwordless SSH access to the template VM from the bastion host:

```bash
ssh \
  -i ~/.ssh/nkp-bastion \
  -o IdentitiesOnly=yes \
  -o BatchMode=yes \
  nutanix@10.68.200.13 \
  'hostname && whoami'
```

## 4. Final steps on the template VM

**Connect to the Ubuntu template VM before starting this section.** Use the configured `nutanix` account.

### 4.1 Clear VM-Specific Identifiers

Run the following commands before converting the VM into a template:

```bash
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
```

Generate any missing SSH host keys without removing existing keys:

```bash
sudo ssh-keygen -A
```

Verify that the required keys exist:

```bash
sudo ls -l /etc/ssh/ssh_host_*_key
```

Clean the logs and APT caches:

```bash
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo journalctl --rotate || true
sudo journalctl --vacuum-time=1s || true
```

### 4.2 Shut Down the Template

Clear the shell history, then shut down the VM:

```bash
history -c
history -w
sudo shutdown -h now
```
The VM is now powered off and ready to become a template.

### 4.3 Convert to Template

On vCenter, convert the VM into a template. The template is now ready to be used to create the control plane and worker nodes.
