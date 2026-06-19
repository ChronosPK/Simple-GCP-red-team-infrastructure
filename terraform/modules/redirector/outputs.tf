output "name" {
  value = google_compute_instance.redirector.name
}

output "internal_ip" {
  value = google_compute_instance.redirector.network_interface[0].network_ip
}
