resource "google_compute_network" "lab" {
  name                    = "${var.name_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "lab" {
  name                     = "${var.name_prefix}-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.lab.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "lab" {
  name    = "${var.name_prefix}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.lab.id
}

resource "google_compute_router_nat" "lab" {
  name                               = "${var.name_prefix}-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.lab.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.lab.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "iap_ssh" {
  name      = "${var.name_prefix}-allow-iap-ssh"
  project   = var.project_id
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "wireguard" {
  name      = "${var.name_prefix}-allow-wireguard"
  project   = var.project_id
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpn-gateway"]

  allow {
    protocol = "udp"
    ports    = [tostring(var.vpn_port)]
  }
}

resource "google_compute_firewall" "student_to_redirector" {
  name      = "${var.name_prefix}-student-to-redirector"
  project   = var.project_id
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = [var.vpn_cidr]
  target_tags   = ["redirector"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

resource "google_compute_firewall" "redirector_to_team_server" {
  name      = "${var.name_prefix}-redirector-to-team-server"
  project   = var.project_id
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_tags = ["redirector"]
  target_tags = ["team-server"]

  allow {
    protocol = "tcp"
    ports    = ["7443"]
  }
}

resource "google_compute_firewall" "vpn_diagnostics" {
  name      = "${var.name_prefix}-vpn-diagnostics"
  project   = var.project_id
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = [var.vpn_cidr]
  target_tags   = ["redirector"]

  allow {
    protocol = "icmp"
  }
}
