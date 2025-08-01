resource "openstack_networking_network_v2" "k3s_net" {
  name           = "k3s-private"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "k3s_subnet" {
  name            = "k3s-subnet"
  network_id      = openstack_networking_network_v2.k3s_net.id
  cidr            = "192.168.100.0/24"
  ip_version      = 4
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "openstack_networking_router_v2" "k3s_router" {
  name                = "k3s-router"
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "k3s_router_interface" {
  router_id = openstack_networking_router_v2.k3s_router.id
  subnet_id = openstack_networking_subnet_v2.k3s_subnet.id
}
