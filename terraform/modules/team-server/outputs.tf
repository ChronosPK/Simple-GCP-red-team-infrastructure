output "name" {
  value = google_compute_instance.team_server.name
}

output "internal_ip" {
  value = google_compute_instance.team_server.network_interface[0].network_ip
}
