output "vpn_endpoint" {
  description = "Public WireGuard endpoint."
  value       = "${module.vpn.public_ip}:${var.vpn_port}"
}

output "redirector_url" {
  description = "Internal training redirector URL; available only after connecting to WireGuard."
  value       = "https://${module.redirector.internal_ip}/"
}

output "team_server_internal_ip" {
  description = "Private Mythic host address."
  value       = module.team_server.internal_ip
}

output "student_config_directory" {
  description = "Locally rendered WireGuard client profiles."
  value       = module.vpn.client_config_directory
}

output "admin_commands" {
  description = "IAP-only administrative access commands. Project-level OS Login determines the Linux username."
  value = {
    vpn         = "gcloud compute ssh ${module.vpn.name} --project ${var.project_id} --zone ${var.zone} --tunnel-through-iap"
    redirector  = "gcloud compute ssh ${module.redirector.name} --project ${var.project_id} --zone ${var.zone} --tunnel-through-iap"
    team_server = "gcloud compute ssh ${module.team_server.name} --project ${var.project_id} --zone ${var.zone} --tunnel-through-iap"
  }
}
