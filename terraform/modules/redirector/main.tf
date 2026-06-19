data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "redirector" {
  name         = "${var.name_prefix}-redirector"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type

  tags = ["redirector", "iap-ssh"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
  }

  metadata = {
    block-project-ssh-keys = "TRUE"
    ssh-keys               = var.ssh_key_metadata
  }

  metadata_startup_script = templatefile("${path.module}/templates/redirector-bootstrap.sh.tftpl", {
    team_server_ip = var.team_server_ip
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}
