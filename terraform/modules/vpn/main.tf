data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_address" "vpn" {
  name         = "${var.name_prefix}-vpn-ip"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
}

locals {
  peer_config = join("\n", [
    for student in var.students : <<-PEER
      [Peer]
      # ${student.name}
      PublicKey = ${student.public_key}
      AllowedIPs = ${student.vpn_ip}/32
    PEER
  ])

  server_config = <<-WG
    [Interface]
    Address = ${cidrhost(var.vpn_cidr, 1)}/${split("/", var.vpn_cidr)[1]}
    ListenPort = ${var.vpn_port}
    PrivateKey = ${var.wireguard_server_private_key}
    PostUp = iptables -I INPUT -i %i -j DROP; iptables -A FORWARD -i %i -o ens4 -d ${var.subnet_cidr} -j ACCEPT; iptables -A FORWARD -i ens4 -o %i -s ${var.subnet_cidr} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT; iptables -A FORWARD -i %i -o %i -j DROP
    PostDown = iptables -D INPUT -i %i -j DROP; iptables -D FORWARD -i %i -o ens4 -d ${var.subnet_cidr} -j ACCEPT; iptables -D FORWARD -i ens4 -o %i -s ${var.subnet_cidr} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT; iptables -D FORWARD -i %i -o %i -j DROP

    ${local.peer_config}
  WG
}

resource "terraform_data" "wireguard_config" {
  input = sha256(local.server_config)
}

resource "google_compute_instance" "vpn" {
  name           = "${var.name_prefix}-vpn"
  project        = var.project_id
  zone           = var.zone
  machine_type   = var.machine_type
  can_ip_forward = true

  tags = ["vpn-gateway", "iap-ssh"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link

    access_config {
      nat_ip       = google_compute_address.vpn.address
      network_tier = "STANDARD"
    }
  }

  metadata = {
    block-project-ssh-keys = "TRUE"
    ssh-keys               = var.ssh_key_metadata
  }

  metadata_startup_script = templatefile("${path.module}/templates/vpn-bootstrap.sh.tftpl", {
    wireguard_config = local.server_config
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  lifecycle {
    replace_triggered_by = [terraform_data.wireguard_config]
  }
}

resource "local_file" "student_config" {
  for_each = { for student in var.students : student.name => student }

  filename        = "${path.root}/generated-clients/${each.key}.conf"
  file_permission = "0600"
  content = templatefile("${path.module}/templates/wg-client.conf.tftpl", {
    student_name      = each.key
    student_ip        = each.value.vpn_ip
    vpn_prefix_length = split("/", var.vpn_cidr)[1]
    server_public_key = var.wireguard_server_public_key
    endpoint          = "${google_compute_address.vpn.address}:${var.vpn_port}"
    subnet_cidr       = var.subnet_cidr
  })
}
