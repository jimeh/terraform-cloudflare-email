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

## Requirements

| Name                                                                        | Version       |
| --------------------------------------------------------------------------- | ------------- |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement_cloudflare) | >= 3.0, < 5.0 |

## Providers

| Name                                                                  | Version       |
| --------------------------------------------------------------------- | ------------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider_cloudflare) | >= 3.0, < 5.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                                                | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [cloudflare_record.dmarc](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                               | resource    |
| [cloudflare_record.domainkeys](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                          | resource    |
| [cloudflare_record.mta-sts-a](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                           | resource    |
| [cloudflare_record.mta-sts-aaaa](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                        | resource    |
| [cloudflare_record.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                             | resource    |
| [cloudflare_record.mx](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                                  | resource    |
| [cloudflare_record.smtp_tls](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                            | resource    |
| [cloudflare_record.spf](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)                                 | resource    |
| [cloudflare_worker_route.mta_sts_route](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_route)           | resource    |
| [cloudflare_worker_script.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_script)               | resource    |
| [cloudflare_workers_kv.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv)                     | resource    |
| [cloudflare_workers_kv_namespace.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv_namespace) | resource    |
| [cloudflare_zone.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone)                                 | data source |

## Inputs

| Name                                                                           | Description                                                                                                                | Type                                                                 | Default                                         | Required |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------- | :------: |
| <a name="input_account_id"></a> [account_id](#input_account_id)                | Cloudflare Account ID                                                                                                      | `string`                                                             | n/a                                             |   yes    |
| <a name="input_dmarc_dkim_mode"></a> [dmarc_dkim_mode](#input_dmarc_dkim_mode) | The DMARC DKIM mode for alignment (options: `relaxed`, `strict`).                                                          | `string`                                                             | `"relaxed"`                                     |    no    |
| <a name="input_dmarc_fo"></a> [dmarc_fo](#input_dmarc_fo)                      | Failure reporting options for DMARC (characters: `0`, `1`, `d`, `s`, separated by `:`).                                    | `string`                                                             | `"1:d:s"`                                       |    no    |
| <a name="input_dmarc_percent"></a> [dmarc_percent](#input_dmarc_percent)       | Percentage of messages to apply the DMARC policy to (0-100).                                                               | `number`                                                             | `100`                                           |    no    |
| <a name="input_dmarc_policy"></a> [dmarc_policy](#input_dmarc_policy)          | The DMARC policy to apply (options: `none`, `quarantine`, `reject`).                                                       | `string`                                                             | `"none"`                                        |    no    |
| <a name="input_dmarc_rua"></a> [dmarc_rua](#input_dmarc_rua)                   | Where aggregate DMARC reports about policy violations should be sent.                                                      | `list(string)`                                                       | n/a                                             |   yes    |
| <a name="input_dmarc_ruf"></a> [dmarc_ruf](#input_dmarc_ruf)                   | Where failure/forensic DMARC reports about policy violations should be sent.                                               | `list(string)`                                                       | `[]`                                            |    no    |
| <a name="input_dmarc_spf_mode"></a> [dmarc_spf_mode](#input_dmarc_spf_mode)    | The DMARC SPF mode for alignment (options: `relaxed`, `strict`).                                                           | `string`                                                             | `"relaxed"`                                     |    no    |
| <a name="input_dmarc_ttl"></a> [dmarc_ttl](#input_dmarc_ttl)                   | TTL for `_dmarc` DNS record. `1` is auto. Default is `1`.                                                                  | `number`                                                             | `1`                                             |    no    |
| <a name="input_domainkeys"></a> [domainkeys](#input_domainkeys)                | Map of domain keys with name, record type (`TXT` or `CNAME`), and value.                                                   | <pre>map(object({<br> type = string<br> value = string<br> }))</pre> | `{}`                                            |    no    |
| <a name="input_mta_sts_max_age"></a> [mta_sts_max_age](#input_mta_sts_max_age) | Maximum lifetime of the policy in seconds, up to 31557600, defaults to 604800 (1 week)                                     | `number`                                                             | `604800`                                        |    no    |
| <a name="input_mta_sts_mode"></a> [mta_sts_mode](#input_mta_sts_mode)          | MTA policy mode, https://tools.ietf.org/html/rfc8461#section-5                                                             | `string`                                                             | `"testing"`                                     |    no    |
| <a name="input_mta_sts_mx"></a> [mta_sts_mx](#input_mta_sts_mx)                | Additional permitted MX hosts for the MTA STS policy.                                                                      | `list(string)`                                                       | `[]`                                            |    no    |
| <a name="input_mx"></a> [mx](#input_mx)                                        | A map representing the MX records. Key is the priority and value is the mail server hostname.                              | `map(number)`                                                        | n/a                                             |   yes    |
| <a name="input_mx_subdomains"></a> [mx_subdomains](#input_mx_subdomains)       | List of sub-domains to also apply MX records to.                                                                           | `list(string)`                                                       | `[]`                                            |    no    |
| <a name="input_record_ttl"></a> [record_ttl](#input_record_ttl)                | TTL for DNS records. `1` is auto. Default is `1`.                                                                          | `number`                                                             | `1`                                             |    no    |
| <a name="input_spf_terms"></a> [spf_terms](#input_spf_terms)                   | List of SPF terms that should be included in the SPF TXT record.                                                           | `list(string)`                                                       | <pre>[<br> "mx",<br> "a",<br> "~all"<br>]</pre> |    no    |
| <a name="input_tlsrpt_rua"></a> [tlsrpt_rua](#input_tlsrpt_rua)                | Locations to which aggregate TLS SMTP reports about policy violations should be sent, either `mailto:` or `https:` schema. | `list(string)`                                                       | n/a                                             |   yes    |
| <a name="input_zone_id"></a> [zone_id](#input_zone_id)                         | Cloudflare Zone ID                                                                                                         | `string`                                                             | n/a                                             |   yes    |

## Outputs

| Name                                                                                      | Description                     |
| ----------------------------------------------------------------------------------------- | ------------------------------- |
| <a name="output_mta_sts_policy_url"></a> [mta_sts_policy_url](#output_mta_sts_policy_url) | URL to the MTA-STS policy file. |
