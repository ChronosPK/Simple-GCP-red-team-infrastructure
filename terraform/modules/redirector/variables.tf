variable "project_id" {
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

variable "machine_type" {
  type = string
}

variable "ssh_key_metadata" {
  type      = string
  sensitive = true
}

variable "team_server_ip" {
  type = string
}
