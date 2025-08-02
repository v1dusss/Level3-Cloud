#!/bin/bash
set -e

ANSIBLE_DIR="/opt/stack/Level3-Cloud/ansible"
INVENTORY_PATH="$ANSIBLE_DIR/inventory_local.ini"
PLAYBOOK_PATH="$ANSIBLE_DIR/install-k3s.yml"
SSH_KEY="~/.ssh/id_rsa.pem"
ANSIBLE_USER="ubuntu"

# Extract floating IP (public) from a given server name
get_fixed_ip() {
    local server_name=$1
    openstack server show "$server_name" -f value -c addresses \
        | grep -oP '\b172\.24\.\d+\.\d+\b' | head -n1
}

echo "[+] Generating dynamic Ansible inventory..."

# --- Master ---
echo "[master]" > "$INVENTORY_PATH"
MASTER_NAME="k3s-master"
MASTER_IP=$(get_fixed_ip "$MASTER_NAME")

if [ -z "$MASTER_IP" ]; then
    echo -e "\e[31mERROR: Could not find fixed IP for master: $MASTER_NAME\e[0m"
    exit 1
fi

echo "master1 ansible_host=$MASTER_IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$SSH_KEY" >> "$INVENTORY_PATH"

# --- Workers ---
echo -e "\n[workers]" >> "$INVENTORY_PATH"

# Loop through all k3s-worker-* instances
WORKER_NAMES=$(openstack server list -f value -c Name | grep '^k3s-worker-')

if [ -z "$WORKER_NAMES" ]; then
    echo -e "\e[33mWARNING: No worker nodes found matching 'k3s-worker-*'\e[0m"
else
    COUNT=1
    while read -r WORKER; do
        IP=$(get_fixed_ip "$WORKER")
        if [ -n "$IP" ]; then
            echo "worker${COUNT} ansible_host=$IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$SSH_KEY" >> "$INVENTORY_PATH"
            COUNT=$((COUNT + 1))
        else
            echo -e "\e[33mWARNING: No fixed IP found for $WORKER\e[0m"
        fi
    done <<< "$WORKER_NAMES"
fi

echo -e "\e[32m[+] Inventory generated at $INVENTORY_PATH\e[0m"

# --- Run Ansible Playbook ---
if [ ! -f "$PLAYBOOK_PATH" ]; then
    echo -e "\e[31mERROR: Playbook not found at $PLAYBOOK_PATH\e[0m"
    exit 1
fi

echo -e "\e[33m[~] Waiting 120 seconds for instances to finish booting...\e[0m"
sleep 120

echo -e "\n[+] Running Ansible playbook: $PLAYBOOK_PATH"
cd "$ANSIBLE_DIR"
ansible-playbook "$PLAYBOOK_PATH"
if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Ansible playbook execution failed\e[0m"
    exit 1
fi
echo -e "\e[32m[+] K3s installation completed successfully!\e[0m"