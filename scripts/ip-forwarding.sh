#!/bin/bash

# Configuration
# Replace these with your actual floating and instance IP addresses
FLOATING_IPS=("FLOATING_IP_1" "FLOATING_IP_2")
INSTANCE_IPS=("INSTANCE_IP_1" "INSTANCE_IP_2")

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Clear existing rules (optional)
sudo iptables -t nat -F PREROUTING
sudo iptables -t nat -F POSTROUTING

# Create NAT rules for each IP pair
for i in "${!FLOATING_IPS[@]}"; do
    FLOATING_IP="${FLOATING_IPS[$i]}"
    INSTANCE_IP="${INSTANCE_IPS[$i]}"

    echo "Mapping $FLOATING_IP -> $INSTANCE_IP"

    # DNAT: Incoming traffic to floating IP goes to instance
    sudo iptables -t nat -A PREROUTING -d $FLOATING_IP -j DNAT --to-destination $INSTANCE_IP

    # SNAT: Outgoing traffic from instance appears to come from floating IP
    sudo iptables -t nat -A POSTROUTING -s $INSTANCE_IP -j SNAT --to-source $FLOATING_IP

    # Allow forwarding
    sudo iptables -A FORWARD -d $INSTANCE_IP -j ACCEPT
    sudo iptables -A FORWARD -s $INSTANCE_IP -j ACCEPT
done

# Save rules
sudo iptables-save > /tmp/iptables-rules
echo "Rules saved to /tmp/iptables-rules"