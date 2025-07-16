variable "auth_url" {}
variable "username" {}
variable "password" {}
variable "project_name" {}
variable "region" {}

variable "image" {
  default = "Ubuntu 22.04 Jammy"
}
variable "flavor" {
  default = "ds1G"
}
variable "keypair" {
  default = "mykey"
}
variable "external_network_name" {
  default = "public"
}

# variable "private_network_id" {}

variable "external_network_id" {
  description = "ID of the external network used for Floating IPs"
}
