#!/bin/bash
set -e

# Assumes local.conf already exists
cd /opt/stack
git clone https://opendev.org/openstack/devstack || true
mv /opt/stack/local.conf /opt/stack/devstack/local.conf
cd devstack

./stack.sh

source ~/devstack/openrc admin admin
wget https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img

openstack image create "Ubuntu 22.04 Jammy" \
   --file ubuntu-22.04-server-cloudimg-amd64.img \
   --disk-format qcow2 \
   --container-format bare

openstack flavor create k3s_flavor --ram 24576 --disk 60 --vcpus 8 --public

cd /opt/stack
git clone https://github.com/v1dusss/Level3-Cloud.git Level3-Cloud
cd Level3-Cloud

# Inject Terraform variables dynamically
TFVARS_PATH="/opt/stack/Level3-Cloud/terraform/terraform.tfvars"
LOCAL_CONF="/opt/stack/devstack/local.conf"

# Extract password
ADMIN_PASS=$(grep '^ADMIN_PASSWORD=' "$LOCAL_CONF" | cut -d= -f2)
if [ -z "$ADMIN_PASS" ]; then
    echo -e "\e[31mERROR: ADMIN_PASSWORD not found in local.conf\e[0m"
    echo "Please ensure that local.conf contains the ADMIN_PASSWORD variable."
    exit 1
fi

# Get public network ID
EXTERNAL_NET_ID=$(openstack network list --name public -f value -c ID)
if [ -z "$EXTERNAL_NET_ID" ]; then
    echo -e "\e[31mERROR: External network 'public' not found\e[0m"
    echo "Please ensure that the 'public' network exists in your OpenStack environment."
    exit 1
fi

# Write terraform.tfvars
cat > "$TFVARS_PATH" <<EOF
auth_url            = "http://localhost/identity/v3"
username            = "admin"
password            = "$ADMIN_PASS"
project_name        = "admin"
region              = "RegionOne"
external_network_id = "$EXTERNAL_NET_ID"
EOF

echo -e "\e[32m[+] terraform.tfvars generated\e[0m"
echo -e "\e[32m[+] terraform.tfvars generated\e[0m"
echo -e "\e[32m[+] terraform.tfvars generated\e[0m"

cd terraform
terraform init
terraform plan -out=tfplan
if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Terraform plan failed\e[0m"
    exit 1
fi
terraform apply -auto-approve

mkdir ~/.ssh
mv k3s-key.pem ~/.ssh/id_rsa.pem
chmod 600 ~/.ssh/id_rsa.pem

echo -e "\e[32m[+] SSH key moved to ~/.ssh/id_rsa.pem\e[0m"