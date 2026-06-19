output "network_self_link" {
  value = google_compute_network.lab.self_link
}

output "subnet_self_link" {
  value = google_compute_subnetwork.lab.self_link
}
