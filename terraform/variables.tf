variable "project_id" {
  description = "GCP project ID used exclusively for the lab."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "europe-central2"
}

variable "zone" {
  description = "GCP zone in region."
  type        = string
  default     = "europe-central2-a"
}

variable "name_prefix" {
  description = "Prefix for all resources."
  type        = string
  default     = "rt-lab"
}

variable "subnet_cidr" {
  description = "CIDR used by GCE instances."
  type        = string
  default     = "10.20.0.0/24"
}

variable "vpn_cidr" {
  description = "WireGuard client CIDR."
  type        = string
  default     = "10.20.100.0/24"
}

variable "vpn_port" {
  description = "Public WireGuard UDP port."
  type        = number
  default     = 51820
}

variable "admin_username" {
  description = "Linux account created by the Debian GCE image from the SSH metadata entry."
  type        = string
  default     = "labadmin"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,30}$", var.admin_username))
    error_message = "admin_username must be a valid Linux username."
  }
}

variable "admin_ssh_public_key" {
  description = "Instructor SSH public key. Administrative SSH is reachable only through GCP IAP."
  type        = string
  sensitive   = true
}

variable "wireguard_server_private_key" {
  description = "WireGuard server private key from `wg genkey`. Pass with TF_VAR_wireguard_server_private_key."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9+/]{43}=$", var.wireguard_server_private_key))
    error_message = "wireguard_server_private_key must be a base64 WireGuard key."
  }
}

variable "wireguard_server_public_key" {
  description = "WireGuard server public key from `wg pubkey`."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9+/]{43}=$", var.wireguard_server_public_key))
    error_message = "wireguard_server_public_key must be a base64 WireGuard key."
  }
}

variable "students" {
  description = "Reserved WireGuard peers. Leave public_key empty until the student submits it."
  type = list(object({
    name       = string
    public_key = string
    vpn_ip     = string
  }))
  default = []

  validation {
    condition = alltrue([
      for student in var.students :
      can(regex("^[a-z][a-z0-9-]{1,30}$", student.name)) &&
      (trimspace(student.public_key) == "" || can(regex("^[A-Za-z0-9+/]{43}=$", trimspace(student.public_key)))) &&
      can(cidrhost("${student.vpn_ip}/32", 0))
    ])
    error_message = "Each student needs a simple lowercase name, an empty or valid WireGuard public key, and an IPv4 vpn_ip."
  }

  validation {
    condition     = length(distinct([for student in var.students : student.name])) == length(var.students)
    error_message = "Student names must be unique."
  }

  validation {
    condition     = length(distinct([for student in var.students : student.vpn_ip])) == length(var.students)
    error_message = "Student VPN IPs must be unique."
  }

  validation {
    condition = length(distinct(compact([
      for student in var.students : trimspace(student.public_key)
      ]))) == length(compact([
      for student in var.students : trimspace(student.public_key)
    ]))
    error_message = "Non-empty student WireGuard public keys must be unique."
  }
}

variable "gateway_machine_type" {
  description = "WireGuard gateway size. e2-small is adequate for 20-30 split-tunnel students."
  type        = string
  default     = "e2-small"
}

variable "redirector_machine_type" {
  description = "Internal Nginx redirector size."
  type        = string
  default     = "e2-micro"
}

variable "team_server_machine_type" {
  description = "Mythic server size. Official minimum is 2 vCPU/4 GB; 4 vCPU/16 GB leaves classroom headroom."
  type        = string
  default     = "e2-standard-4"
}

variable "mythic_version" {
  description = "Pinned Mythic Git tag."
  type        = string
  default     = "v3.4.0.5"
}

variable "install_mythic" {
  description = "Install and start Mythic during first boot. Disable to provision infrastructure only."
  type        = bool
  default     = true
}
