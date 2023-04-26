output "mta_sts_policy_url" {
  value       = "https://mta-sts.${local.zone_name}/.well-known/mta-sts.txt"
  description = "URL to the MTA-STS policy file."
}
