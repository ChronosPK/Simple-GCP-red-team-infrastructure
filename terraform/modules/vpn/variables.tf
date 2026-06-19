variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "subnet_self_link" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "vpn_cidr" {
  type = string
}

variable "vpn_port" {
  type = number
}

variable "machine_type" {
  type = string
}

variable "ssh_key_metadata" {
  type      = string
  sensitive = true
}

variable "wireguard_server_private_key" {
  type      = string
  sensitive = true
}

variable "wireguard_server_public_key" {
  type = string
}

variable "students" {
  type = list(object({
    name       = string
    public_key = string
    vpn_ip     = string
  }))
}
