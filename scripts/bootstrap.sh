#!/bin/bash
set -e

# 1. Create stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack || true
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

# 2. Copy script into stack's home for continuation
sudo cp $0 /opt/stack/bootstrap.sh
sudo chown stack:stack /opt/stack/bootstrap.sh

# 3. Switch to stack user and continue setup
sudo -u stack -i bash /opt/stack/bootstrap.sh --as-stack-user
exit 0
