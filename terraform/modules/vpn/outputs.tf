output "name" {
  value = google_compute_instance.vpn.name
}

output "public_ip" {
  value = google_compute_address.vpn.address
}

output "instance_self_link" {
  value = google_compute_instance.vpn.self_link
}

output "client_config_directory" {
  value = "${path.root}/generated-clients"
}
