data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "team_server" {
  name         = "${var.name_prefix}-team-server"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type

  tags = ["team-server", "iap-ssh"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 80
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
  }

  metadata = {
    block-project-ssh-keys = "TRUE"
    ssh-keys               = var.ssh_key_metadata
  }

  metadata_startup_script = templatefile("${path.module}/templates/ts-bootstrap.sh.tftpl", {
    install_mythic = var.install_mythic
    mythic_version = var.mythic_version
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}
