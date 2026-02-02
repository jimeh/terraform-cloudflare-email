<h1 align="center">
  terraform-cloudflare-email
</h1>

<p align="center">
  <strong>
    Terraform module to configure various email related DNS records on
    Cloudflare.
  </strong>
</p>

<p align="center">
  <a href="https://github.com/jimeh/terraform-cloudflare-email/releases">
    <img src="https://img.shields.io/github/v/tag/jimeh/terraform-cloudflare-email?label=release" alt="GitHub tag (latest SemVer)">
  </a>
  <a href="https://github.com/jimeh/terraform-cloudflare-email/issues">
    <img src="https://img.shields.io/github/issues-raw/jimeh/terraform-cloudflare-email.svg?style=flat&logo=github&logoColor=white" alt="GitHub issues">
  </a>
  <a href="https://github.com/jimeh/terraform-cloudflare-email/pulls">
    <img src="https://img.shields.io/github/issues-pr-raw/jimeh/terraform-cloudflare-email.svg?style=flat&logo=github&logoColor=white" alt="GitHub pull requests">
  </a>
  <a href="https://github.com/jimeh/terraform-cloudflare-email/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/jimeh/terraform-cloudflare-email.svg?style=flat" alt="License Status">
  </a>
</p>

Module that configures various email related DNS records on Cloudflare,
including serving a MTA-STS policy text file via Cloudflare Workers.

## Features

- Configure MX records.
- Configure SPF record.
- Configure DMARC record.
- Configure SMTP TLS reporting record.
- Configure MTA-STS record, generate `mta-sts.txt` policy file and serve it with
  a Cloudflare Worker on
  `https://mta-sts.<your-domain>/.well-known/mta-sts.txt`.
- Configure domain key records (`<selector>._domainkey.<your-domain>`).

## Example Usage

<!-- x-release-please-start-version -->

Examples assume that you have the following variables setup:

- `cloudflare_account_id` — Your Account ID.
- `cloudflare_zone_id` — ID of the Zone (domain name).
- `cloudflare_zone_name` — Domain name, e.g. `foobar.com`.

Adjust examples as needed to fit your setup.

### Google Workspace

Below example is based on the
[DNS Basics](https://support.google.com/a/answer/48090?hl=en) support article.
When going through the domain setup wizard within the Google Workspace Admin,
you are likely to be given a slightly different list of MX records, and
obviously you should use the ones that are given to you by Google.

Also make sure you generate your own domain key from under Apps > Google
Workspace > Gmail > Authenticate Email.

<details>
<summary><code>main.tf</code></summary>

```terraform
module "email" {
  source  = "jimeh/email/cloudflare"
  version = "0.0.2"

  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id

  mx = {
    "aspmx.l.google.com"      = 1
    "alt1.aspmx.l.google.com" = 5
    "alt2.aspmx.l.google.com" = 5
    "aspmx2.googlemail.com"   = 10
    "aspmx3.googlemail.com"   = 10
  }

  spf_terms = [
    "include:_spf.google.com",
    "~all",
  ]

  mta_sts_mode    = "enforce"
  mta_sts_max_age = 86400
  mta_sts_mx = [
    "*.aspmx.l.google.com",
    "*.googlemail.com",
    "aspmx.l.google.com",
  ]

  tlsrpt_rua = [
    "mailto:tls-report@${var.cloudflare_zone_name}",
  ]

  dmarc_policy = "reject"
  dmarc_rua = [
    "mailto:dmarc-report@${var.cloudflare_zone_name}",
  ]

  domainkeys = {
    "google" = {
      type = "TXT"
      value = join("", [
        # TODO: Replace this example key with a real one.
        "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApAVNwJ9",
        "+6ArXN23ZaR8SFSYxVEEbbHRZplZqHVt6uEpcirY+jxHOqV2bvqAY3BHZQs/KoHnFSWUf",
        "6zv6ajZgUxvU65UhCbrQ7CwrJCjU8sQFDk+CpbvmXyJIe9G470HuGEs4NmQDoddJZr09V",
        "7d3anX8n7ePSCsIxwGi53DMhwijQXqHYMFALml+QIMZ/03ydL6/B3EwDNDFSBSEqzt2QS",
        "N43EYb3FlUiGu5NGHl3gibEsbywTmGtN3kmkp/rxqaJPLv16NVpTe+0lAqPiq/pgJT4pp",
        "ACz2ENh6BD0H+hDiCKBiw+gyAeDbOn1c5yslENSEyDxqpn17tnxo+O/ZFmwIDAQAB"
      ])
    }
  }
}

resource "cloudflare_record" "cname" {
  for_each = {
    "mail" = { value = "ghs.googlehosted.com", proxied = false }
  }

  name    = lookup(each.value, "name", each.key)
  proxied = lookup(each.value, "proxied", false)
  ttl     = lookup(each.value, "ttl", 1)
  type    = "CNAME"
  value   = each.value.value
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_record" "txt" {
  for_each = {
    "google" = {
      value = (
        "google-site-verification=__REPLACE_ME_WITH_A_REAL_VALUE__"
      )
    }
  }

  name    = lookup(each.value, "name", local.zone_name)
  proxied = lookup(each.value, "proxied", false)
  ttl     = lookup(each.value, "ttl", 1)
  type    = "TXT"
  value   = each.value.value
  zone_id = var.cloudflare_zone_id
}
```

</details>

### Fastmail

The below example is based on Fastmail's
[Manual DNS configuration](https://www.fastmail.help/hc/en-us/articles/360060591153-Manual-DNS-configuration)
help article.

<details>
<summary><code>main.tf</code></summary>

```terraform
module "email" {
  source  = "jimeh/email/cloudflare"
  version = "0.0.2"

  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id

  mx = {
    "in1-smtp.messagingengine.com" = 10
    "in2-smtp.messagingengine.com" = 20
  }
  mx_subdomains = ["*"]

  spf_terms = [
    "include:spf.messagingengine.com",
    "?all"
  ]

  mta_sts_mode    = "enforce"
  mta_sts_max_age = 86400
  mta_sts_mx = [
    "in1-smtp.messagingengine.com",
    "in2-smtp.messagingengine.com",
  ]

  tlsrpt_rua = [
    "mailto:tls-report@${var.cloudflare_zone_name}",
  ]

  dmarc_policy = "reject"
  dmarc_rua = [
    "mailto:dmarc-report@${var.cloudflare_zone_name}",
  ]

  domainkeys = {
    "fm1" = {
      type  = "CNAME"
      value = "fm1.${var.cloudflare_zone_name}.dkim.fmhosted.com"
    }
    "fm2" = {
      type  = "CNAME"
      value = "fm2.${var.cloudflare_zone_name}.dkim.fmhosted.com"
    }
    "fm3" = {
      type  = "CNAME"
      value = "fm3.${var.cloudflare_zone_name}.dkim.fmhosted.com"
    }
    "mesmtp" = {
      type  = "CNAME"
      value = "mesmtp.${var.cloudflare_zone_name}.dkim.fmhosted.com"
    }
  }
}

resource "cloudflare_record" "srv" {
  for_each = {
    "_caldav._tcp" = {}
    "_caldavs._tcp" = {
      port   = 433
      target = "caldav.fastmail.com"
      weight = 1
    }
    "_carddav._tcp" = {}
    "_carddavs._tcp" = {
      port   = 443
      target = "carddav.fastmail.com"
      weight = 1
    }
    "_imap._tcp" = {}
    "_imaps._tcp" = {
      port   = 993
      target = "imap.fastmail.com"
      weight = 1
    }
    "_jmap._tcp" = {
      port   = 443
      target = "jmap.fastmail.com"
      weight = 1
    }
    "_pop3._tcp" = {}
    "_pop3s._tcp" = {
      port     = 995
      priority = 10
      target   = "pop.fastmail.com"
      weight   = 1
    }
    "_submission._tcp" = {
      port   = 587
      target = "smtp.fastmail.com"
      weight = 1
    }
  }

  name    = lookup(each.value, "name", each.key)
  proxied = lookup(each.value, "proxied", false)
  ttl     = lookup(each.value, "ttl", 1)
  type    = "SRV"
  zone_id = var.cloudflare_zone_id
  data {
    name     = var.cloudflare_zone_name
    port     = lookup(each.value, "port", 0)
    priority = lookup(each.value, "priority", 0)
    proto    = split(".", each.key)[1]
    service  = split(".", each.key)[0]
    target   = lookup(each.value, "target", ".")
    weight   = lookup(each.value, "weight", 0)
  }
}
```

</details>

<!-- x-release-please-end -->

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | >= 3.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 3.0, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_record.dmarc](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.domainkeys](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.mta-sts-a](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.mta-sts-aaaa](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.mx](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.smtp_tls](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_record.spf](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_worker_route.mta_sts_route](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_route) | resource |
| [cloudflare_worker_script.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_script) | resource |
| [cloudflare_workers_kv.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv_namespace.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv_namespace) | resource |
| [cloudflare_zone.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare Account ID | `string` | n/a | yes |
| <a name="input_dmarc_dkim_mode"></a> [dmarc\_dkim\_mode](#input\_dmarc\_dkim\_mode) | The DMARC DKIM mode for alignment (options: `relaxed`, `strict`). | `string` | `"relaxed"` | no |
| <a name="input_dmarc_fo"></a> [dmarc\_fo](#input\_dmarc\_fo) | Failure reporting options for DMARC (characters: `0`, `1`, `d`, `s`, separated by `:`). | `string` | `"1:d:s"` | no |
| <a name="input_dmarc_percent"></a> [dmarc\_percent](#input\_dmarc\_percent) | Percentage of messages to apply the DMARC policy to (0-100). | `number` | `100` | no |
| <a name="input_dmarc_policy"></a> [dmarc\_policy](#input\_dmarc\_policy) | The DMARC policy to apply (options: `none`, `quarantine`, `reject`). | `string` | `"none"` | no |
| <a name="input_dmarc_rua"></a> [dmarc\_rua](#input\_dmarc\_rua) | Where aggregate DMARC reports about policy violations should be sent. | `list(string)` | n/a | yes |
| <a name="input_dmarc_ruf"></a> [dmarc\_ruf](#input\_dmarc\_ruf) | Where failure/forensic DMARC reports about policy violations should be sent. | `list(string)` | `[]` | no |
| <a name="input_dmarc_spf_mode"></a> [dmarc\_spf\_mode](#input\_dmarc\_spf\_mode) | The DMARC SPF mode for alignment (options: `relaxed`, `strict`). | `string` | `"relaxed"` | no |
| <a name="input_dmarc_ttl"></a> [dmarc\_ttl](#input\_dmarc\_ttl) | TTL for `_dmarc` DNS record. `1` is auto. Default is `1`. | `number` | `1` | no |
| <a name="input_domainkeys"></a> [domainkeys](#input\_domainkeys) | Map of domain keys with name, record type (`TXT` or `CNAME`), and value. | <pre>map(object({<br/>    type  = string<br/>    value = string<br/>  }))</pre> | `{}` | no |
| <a name="input_mta_sts_max_age"></a> [mta\_sts\_max\_age](#input\_mta\_sts\_max\_age) | Maximum lifetime of the policy in seconds, up to 31557600, defaults to 604800 (1 week) | `number` | `604800` | no |
| <a name="input_mta_sts_mode"></a> [mta\_sts\_mode](#input\_mta\_sts\_mode) | MTA policy mode, https://tools.ietf.org/html/rfc8461#section-5 | `string` | `"testing"` | no |
| <a name="input_mta_sts_mx"></a> [mta\_sts\_mx](#input\_mta\_sts\_mx) | Additional permitted MX hosts for the MTA STS policy. | `list(string)` | `[]` | no |
| <a name="input_mx"></a> [mx](#input\_mx) | A map representing the MX records. Key is the mail server hostname and value is the priority. | `map(number)` | n/a | yes |
| <a name="input_mx_subdomains"></a> [mx\_subdomains](#input\_mx\_subdomains) | List of sub-domains to also apply MX records to. | `list(string)` | `[]` | no |
| <a name="input_record_ttl"></a> [record\_ttl](#input\_record\_ttl) | TTL for DNS records. `1` is auto. Default is `1`. | `number` | `1` | no |
| <a name="input_spf_terms"></a> [spf\_terms](#input\_spf\_terms) | List of SPF terms that should be included in the SPF TXT record. | `list(string)` | <pre>[<br/>  "mx",<br/>  "a",<br/>  "~all"<br/>]</pre> | no |
| <a name="input_tlsrpt_rua"></a> [tlsrpt\_rua](#input\_tlsrpt\_rua) | Locations to which aggregate TLS SMTP reports about policy violations should be sent, either `mailto:` or `https:` schema. | `list(string)` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare Zone ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mta_sts_policy_url"></a> [mta\_sts\_policy\_url](#output\_mta\_sts\_policy\_url) | URL to the MTA-STS policy file. |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
