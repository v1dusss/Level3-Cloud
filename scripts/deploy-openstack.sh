#!/bin/bash
set -e

# Assumes local.conf already exists
cd /opt/stack
git clone https://opendev.org/openstack/devstack || true
mv local.conf devstack/local.conf
cd devstack

./stack.sh

source ~/devstack/openrc admin admin
wget https://cloud-images.ubuntu.com/jammy/20250523/jammy-server-cloudimg-amd64.img

openstack image create "Ubuntu 22.04 Jammy" \
   --file jammy-server-cloudimg-amd64.img \
   --disk-format qcow2 \
   --container-format bare

cd /opt/stack
git clone https://github.com/v1dusss/Level3-Cloud.git Level3-Cloud
cd Level3-Cloud
# cd terraform
# terraform init
# terraform apply -auto-approve