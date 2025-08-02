#!/bin/bash
set -e

# 1. Create stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack || true
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

# 2. Create devstack directory and local.conf
sudo mkdir -p /opt/stack/devstack
sudo curl -o /opt/stack/local.conf https://docs.openstack.org/devstack/latest/_downloads/d6fbba8d6ab5e970a86dd2ca0b884098/local.conf
sudo chown -R stack:stack /opt/stack/devstack

# 3. Copy script into stack's home for continuation
sudo cp $0 /opt/stack/bootstrap.sh
sudo chown stack:stack /opt/stack/bootstrap.sh

# 4. Install Terraform (latest stable)
echo "Installing Terraform..."
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
echo "Terraform installed: $(terraform -version | head -n 1)"

# 5. Install Ansible
echo "Installing Ansible..."
sudo apt-get install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible
echo "Ansible installed: $(ansible --version | head -n 1)"

exit 0
