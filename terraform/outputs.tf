output "master_floating_ip" {
  value = openstack_networking_floatingip_v2.master_fip.address
}

output "worker_floating_ips" {
  value = [for ip in openstack_networking_floatingip_v2.worker_fips : ip.address]
}

output "private_key" {
  value     = tls_private_key.k3s_key.private_key_pem
  sensitive = true
}

resource "local_file" "private_key_file" {
  content         = tls_private_key.k3s_key.private_key_pem
  filename        = "${path.module}/k3s-key.pem"
  file_permission = "0600"
}