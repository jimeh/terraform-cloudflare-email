# State migration helpers for Cloudflare provider v4 → v5 upgrade.
# These allow existing users to upgrade without manual state manipulation
# for renamed resources. Can be removed in a future major release.

# MX
moved {
  from = cloudflare_record.mx
  to   = cloudflare_dns_record.mx
}

# SPF
moved {
  from = cloudflare_record.spf
  to   = cloudflare_dns_record.spf
}

# TLS SMTP
moved {
  from = cloudflare_record.smtp_tls
  to   = cloudflare_dns_record.smtp_tls
}

# MTA-STS
moved {
  from = cloudflare_record.mta-sts-a
  to   = cloudflare_dns_record.mta-sts-a
}

moved {
  from = cloudflare_record.mta-sts-aaaa
  to   = cloudflare_dns_record.mta-sts-aaaa
}

moved {
  from = cloudflare_record.mta_sts
  to   = cloudflare_dns_record.mta_sts
}

moved {
  from = cloudflare_worker_route.mta_sts_route
  to   = cloudflare_workers_route.mta_sts_route
}

# DMARC
moved {
  from = cloudflare_record.dmarc
  to   = cloudflare_dns_record.dmarc
}

# Domain Keys (DKIM)
moved {
  from = cloudflare_record.domainkeys
  to   = cloudflare_dns_record.domainkeys
}
