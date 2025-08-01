terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.0.0"
    }
  }
}

provider "openstack" {
  auth_url            = var.auth_url
  user_name           = var.username
  password            = var.password
  tenant_name         = var.project_name
  region              = var.region
}

# ----------------------------
# SSH Security Group
# ----------------------------
resource "openstack_networking_secgroup_v2" "ssh_access" {
  name        = "ssh-access"
  description = "Allow SSH from anywhere"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_rule_22" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh_access.id
}

resource "openstack_networking_secgroup_rule_v2" "k3s_api_6443" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh_access.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh_access.id
}

resource "openstack_networking_port_v2" "master_port" {
  name       = "k3s-master-port"
  network_id = openstack_networking_network_v2.k3s_net.id

  security_group_ids = [
    openstack_networking_secgroup_v2.ssh_access.id
  ]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.k3s_subnet.id
  }

}

resource "tls_private_key" "k3s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack_compute_keypair_v2" "k3s_key" {
  name       = "mykey"
  public_key = tls_private_key.k3s_key.public_key_openssh
}

# ----------------------------
# Master VM
# ----------------------------
resource "openstack_compute_instance_v2" "master" {
  name            = "k3s-master"
  image_name      = var.image
  flavor_name     = var.master_flavor
  key_pair        = openstack_compute_keypair_v2.k3s_key.name


  network {
    port = openstack_networking_port_v2.master_port.id
  }
}

# ----------------------------
# Floating IP for Master
# ----------------------------
resource "openstack_networking_floatingip_v2" "master_fip" {
  pool = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "master_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.master_fip.address
  port_id     = openstack_networking_port_v2.master_port.id
}

resource "openstack_networking_port_v2" "worker_ports" {
  count      = 1
  name       = "k3s-worker-port-${count.index + 1}"
  network_id = openstack_networking_network_v2.k3s_net.id

  security_group_ids = [
    openstack_networking_secgroup_v2.ssh_access.id
  ]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.k3s_subnet.id
  }

}

# ----------------------------
# Worker VMs
# ----------------------------

resource "openstack_compute_instance_v2" "worker" {
  count           = 1
  name            = "k3s-worker-${count.index + 1}"
  image_name      = var.image
  flavor_name     = var.worker_flavor
  key_pair        = openstack_compute_keypair_v2.k3s_key.name
  security_groups = [openstack_networking_secgroup_v2.ssh_access.name]

  network {
    port = openstack_networking_port_v2.worker_ports[count.index].id
  }
}

# ----------------------------
# Floating IPs for Worker Nodes
# ----------------------------
resource "openstack_networking_floatingip_v2" "worker_fips" {
  count = 1
  pool  = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "worker_fip_assoc" {
  count       = 1
  floating_ip = openstack_networking_floatingip_v2.worker_fips[count.index].address
  port_id     = openstack_networking_port_v2.worker_ports[count.index].id
}
