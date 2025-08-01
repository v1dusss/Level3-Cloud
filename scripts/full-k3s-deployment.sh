#!/bin/bash
set -e

INVENTORY_PATH="./ansible/inventory_local.ini"
PLAYBOOK_PATH="./ansible/install-k3s.yml"
SSH_KEY="~/.ssh/id_rsa.pem"
ANSIBLE_USER="ubuntu"

# Extract floating IP (public) from a given server name
get_floating_ip() {
    local server_name=$1
    openstack server show "$server_name" -f value -c addresses \
        | grep -oP '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b' \
        | grep -v '^172\.24\.4\.' | head -n1
}

echo "[+] Generating dynamic Ansible inventory..."

# --- Master ---
echo "[master]" > "$INVENTORY_PATH"
MASTER_NAME="k3s-master"
MASTER_IP=$(get_floating_ip "$MASTER_NAME")

if [ -z "$MASTER_IP" ]; then
    echo -e "\e[31mERROR: Could not find floating IP for master: $MASTER_NAME\e[0m"
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
        IP=$(get_floating_ip "$WORKER")
        if [ -n "$IP" ]; then
            echo "worker${COUNT} ansible_host=$IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$SSH_KEY" >> "$INVENTORY_PATH"
            COUNT=$((COUNT + 1))
        else
            echo -e "\e[33mWARNING: No floating IP found for $WORKER\e[0m"
        fi
    done <<< "$WORKER_NAMES"
fi

echo -e "\e[32m[+] Inventory generated at $INVENTORY_PATH\e[0m"

# --- Run Ansible Playbook ---
if [ ! -f "$PLAYBOOK_PATH" ]; then
    echo -e "\e[31mERROR: Playbook not found at $PLAYBOOK_PATH\e[0m"
    exit 1
fi

echo -e "\n[+] Running Ansible playbook: $PLAYBOOK_PATH"
ansible-playbook -i "$INVENTORY_PATH" "$PLAYBOOK_PATH"
