#
# General
#

data "cloudflare_zone" "zone" {
  zone_id = var.zone_id
}

locals {
  zone_name = data.cloudflare_zone.zone.name
}

#
# MX
#

locals {
  mx_sets = flatten([
    for name in concat([local.zone_name], var.mx_subdomains) : [
      for mx, priority in var.mx : {
        name     = name
        mx       = mx
        priority = priority
      } if name != ""
    ]
  ])
  mx_records = {
    for v in local.mx_sets :
    "${v.name == local.zone_name ? "" : "${v.name}:"}${v.mx}" => v
  }
}

resource "cloudflare_dns_record" "mx" {
  for_each = local.mx_records

  name     = each.value.name
  priority = each.value.priority
  proxied  = false
  ttl      = var.record_ttl
  type     = "MX"
  content  = each.value.mx
  zone_id  = var.zone_id
}

#
# SPF
#

resource "cloudflare_dns_record" "spf" {
  name    = local.zone_name
  proxied = false
  ttl     = var.record_ttl
  type    = "TXT"
  content = join(" ", concat(["v=spf1"], var.spf_terms))
  zone_id = var.zone_id
}

#
# TLS SMTP
#

resource "cloudflare_dns_record" "smtp_tls" {
  name    = "_smtp._tls"
  ttl     = var.record_ttl
  type    = "TXT"
  content = "v=TLSRPTv1; rua=${join(",", var.tlsrpt_rua)}"
  zone_id = var.zone_id
}

#
# MTA-STS
#

locals {
  policy = templatefile("${path.module}/mta-sts.txt.tpl", {
    mode    = var.mta_sts_mode
    max_age = var.mta_sts_max_age
    mx      = sort(distinct(concat(keys(var.mx), var.mta_sts_mx)))
  })
  policy_sha  = sha1(local.policy)
  worker_name = "mta-sts-${replace(local.zone_name, "/[^A-Za-z0-9-]/", "-")}"
}

resource "cloudflare_dns_record" "mta-sts-a" {
  name    = "mta-sts"
  proxied = true
  ttl     = var.record_ttl
  type    = "A"
  content = "192.0.2.1"
  zone_id = var.zone_id
}

resource "cloudflare_dns_record" "mta-sts-aaaa" {
  name    = "mta-sts"
  proxied = true
  ttl     = var.record_ttl
  type    = "AAAA"
  content = "100::"
  zone_id = var.zone_id
}

resource "cloudflare_dns_record" "mta_sts" {
  name    = "_mta-sts"
  ttl     = var.record_ttl
  type    = "TXT"
  content = "v=STSv1; id=${local.policy_sha}"
  zone_id = var.zone_id
}

resource "cloudflare_workers_kv_namespace" "mta_sts" {
  title      = "mta-sts.${local.zone_name}"
  account_id = var.account_id
}

resource "cloudflare_workers_kv" "mta_sts" {
  namespace_id = cloudflare_workers_kv_namespace.mta_sts.id
  key_name     = "mta-sts.txt"
  value        = local.policy
  account_id   = var.account_id
}

resource "cloudflare_worker" "mta_sts" {
  account_id = var.account_id
  name       = local.worker_name
}

resource "cloudflare_worker_version" "mta_sts" {
  account_id = var.account_id
  worker_id  = cloudflare_worker.mta_sts.name

  main_module = "mta-sts.js"
  modules = [{
    name         = "mta-sts.js"
    content_file = "${path.module}/mta-sts.js"
    content_type = "application/javascript+module"
  }]

  bindings = [{
    name         = "FILES"
    type         = "kv_namespace"
    namespace_id = cloudflare_workers_kv_namespace.mta_sts.id
  }]
}

resource "cloudflare_workers_deployment" "mta_sts" {
  account_id  = var.account_id
  script_name = cloudflare_worker.mta_sts.name
  strategy    = "percentage"

  versions = [{
    percentage = 100
    version_id = cloudflare_worker_version.mta_sts.id
  }]
}

resource "cloudflare_workers_route" "mta_sts_route" {
  pattern = "mta-sts.${local.zone_name}/*"
  script  = cloudflare_worker.mta_sts.name
  zone_id = var.zone_id
}

#
# DMARC
#

locals {
  dmarc_modes = {
    "relaxed" = "r"
    "strict"  = "s"
  }
  dmarc_values = {
    "rua" = join(",", compact(var.dmarc_rua))
    "ruf" = join(",", compact(var.dmarc_ruf))
  }
}

resource "cloudflare_dns_record" "dmarc" {
  name    = "_dmarc"
  proxied = false
  ttl     = floor(var.dmarc_ttl)
  type    = "TXT"
  content = join(" ", flatten([
    "v=DMARC1;",
    "p=${var.dmarc_policy};",
    "pct=${floor(var.dmarc_percent)};",
    "aspf=${local.dmarc_modes[var.dmarc_spf_mode]};",
    "adkim=${local.dmarc_modes[var.dmarc_dkim_mode]};",
    [
      for k, v in local.dmarc_values :
      "${k}=${v};" if trimspace(v) != ""
    ],
    [
      for v in [var.dmarc_fo] :
      "fo=${v};" if trimspace(local.dmarc_values["ruf"]) != ""
    ],
  ]))
  zone_id = var.zone_id
}

#
# Domain Keys (DKIM)
#

resource "cloudflare_dns_record" "domainkeys" {
  for_each = var.domainkeys

  name    = "${each.key}._domainkey"
  proxied = false
  ttl     = var.record_ttl
  type    = upper(each.value.type)
  content = each.value.value
  zone_id = var.zone_id
}
