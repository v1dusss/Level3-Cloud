#!/bin/bash
set -e

# 1. Create stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack || true
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

# 2. Create devstack directory and local.conf
sudo mkdir -p /opt/stack/devstack
sudo curl -o /opt/stack/devstack/local.conf https://docs.openstack.org/devstack/latest/_downloads/d6fbba8d6ab5e970a86dd2ca0b884098/local.conf
sudo chown -R stack:stack /opt/stack/devstack

# 3. Copy script into stack's home for continuation
sudo cp $0 /opt/stack/bootstrap.sh
sudo chown stack:stack /opt/stack/bootstrap.sh

exit 0
