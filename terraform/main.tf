locals {
  ssh_key_metadata = "${var.admin_username}:${trimspace(var.admin_ssh_public_key)}"
  active_students = [
    for student in var.students : merge(student, {
      public_key = trimspace(student.public_key)
    }) if trimspace(student.public_key) != ""
  ]
}

resource "google_project_service" "required" {
  for_each = toset([
    "compute.googleapis.com",
    "iap.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "network" {
  source = "./modules/network"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
  subnet_cidr = var.subnet_cidr
  vpn_cidr    = var.vpn_cidr
  vpn_port    = var.vpn_port

  depends_on = [google_project_service.required]
}

module "vpn" {
  source = "./modules/vpn"

  project_id                   = var.project_id
  region                       = var.region
  zone                         = var.zone
  name_prefix                  = var.name_prefix
  subnet_self_link             = module.network.subnet_self_link
  subnet_cidr                  = var.subnet_cidr
  vpn_cidr                     = var.vpn_cidr
  vpn_port                     = var.vpn_port
  machine_type                 = var.gateway_machine_type
  ssh_key_metadata             = local.ssh_key_metadata
  wireguard_server_private_key = var.wireguard_server_private_key
  wireguard_server_public_key  = var.wireguard_server_public_key
  students                     = local.active_students
}

module "team_server" {
  source = "./modules/team-server"

  project_id       = var.project_id
  zone             = var.zone
  name_prefix      = var.name_prefix
  subnet_self_link = module.network.subnet_self_link
  machine_type     = var.team_server_machine_type
  ssh_key_metadata = local.ssh_key_metadata
  mythic_version   = var.mythic_version
  install_mythic   = var.install_mythic
}

module "redirector" {
  source = "./modules/redirector"

  project_id       = var.project_id
  zone             = var.zone
  name_prefix      = var.name_prefix
  subnet_self_link = module.network.subnet_self_link
  machine_type     = var.redirector_machine_type
  ssh_key_metadata = local.ssh_key_metadata
  team_server_ip   = module.team_server.internal_ip
}

resource "google_compute_route" "vpn_clients" {
  name                   = "${var.name_prefix}-vpn-clients"
  project                = var.project_id
  network                = module.network.network_self_link
  dest_range             = var.vpn_cidr
  priority               = 900
  next_hop_instance      = module.vpn.instance_self_link
  next_hop_instance_zone = var.zone
}
