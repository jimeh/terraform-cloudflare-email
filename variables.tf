#
# General
#

variable "account_id" {
  type        = string
  description = "Cloudflare Account ID"
}

variable "zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
}

variable "record_ttl" {
  type        = number
  default     = 1
  nullable    = false
  description = "TTL for DNS records. `1` is auto. Default is `1`."
}

#
# MX
#

variable "mx" {
  type        = map(number)
  description = "A map representing the MX records. Key is the priority and value is the mail server hostname."

  validation {
    condition     = length(var.mx) > 0
    error_message = "At least one MX record is required."
  }
}

variable "mx_subdomains" {
  type        = list(string)
  description = "List of sub-domains to also apply MX records to."
  default     = []
}

#
# SPF
#

variable "spf_terms" {
  type        = list(string)
  default     = ["mx", "a", "~all"]
  description = "List of SPF terms that should be included in the SPF TXT record."
}

#
# TLS SMTP
#

variable "tlsrpt_rua" {
  type        = list(string)
  description = "Locations to which aggregate TLS SMTP reports about policy violations should be sent, either `mailto:` or `https:` schema."

  validation {
    condition     = length(var.tlsrpt_rua) != 0
    error_message = "At least one `mailto:` or `https:` endpoint provided."
  }

  validation {
    condition = can([
      for loc in var.tlsrpt_rua : regex("^(mailto|https):", loc)
    ])
    error_message = "Locations must start with either the `mailto:` or `https` schema."
  }
}

#
# MTA-STS
#

variable "mta_sts_mode" {
  type        = string
  default     = "testing"
  description = "MTA policy mode, https://tools.ietf.org/html/rfc8461#section-5"

  validation {
    condition     = contains(["enforce", "testing", "none"], var.mta_sts_mode)
    error_message = "Must be `enforce`, `testing`, or `none`."
  }
}

variable "mta_sts_max_age" {
  type        = number
  default     = 604800 # 1 week
  description = "Maximum lifetime of the policy in seconds, up to 31557600, defaults to 604800 (1 week)"

  validation {
    condition     = var.mta_sts_max_age >= 0
    error_message = "Policy validity time must be positive."
  }

  validation {
    condition     = var.mta_sts_max_age <= 31557600
    error_message = "Policy validity time must be less than 1 year (31557600 seconds)."
  }
}

variable "mta_sts_mx" {
  type        = list(string)
  default     = []
  description = "Additional permitted MX hosts for the MTA STS policy."
}

#
# DMARC
#

variable "dmarc_policy" {
  type        = string
  default     = "none"
  description = "The DMARC policy to apply (options: `none`, `quarantine`, `reject`)."

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "Must be `none`, `quarantine`, or `reject`."
  }
}

variable "dmarc_spf_mode" {
  type        = string
  default     = "relaxed"
  description = "The DMARC SPF mode for alignment (options: `relaxed`, `strict`)."

  validation {
    condition     = contains(["relaxed", "strict"], var.dmarc_spf_mode)
    error_message = "Must be `relaxed` or `strict`."
  }
}

variable "dmarc_dkim_mode" {
  type        = string
  default     = "relaxed"
  description = "The DMARC DKIM mode for alignment (options: `relaxed`, `strict`)."

  validation {
    condition     = contains(["relaxed", "strict"], var.dmarc_dkim_mode)
    error_message = "Must be `relaxed` or `strict`."
  }
}

variable "dmarc_percent" {
  type        = number
  default     = 100
  description = "Percentage of messages to apply the DMARC policy to (0-100)."

  validation {
    condition     = var.dmarc_percent > 0 && var.dmarc_percent <= 100
    error_message = "Must be between 0 and 100."
  }
}

variable "dmarc_ttl" {
  type        = number
  default     = 1
  description = "TTL for `_dmarc` DNS record. `1` is auto. Default is `1`."

  validation {
    condition     = var.dmarc_ttl > 0 && var.dmarc_ttl <= 604800
    error_message = "Must be between 1 and 604800."
  }
}

variable "dmarc_rua" {
  type        = list(string)
  description = "Where aggregate DMARC reports about policy violations should be sent."

  validation {
    condition     = length(var.dmarc_rua) != 0
    error_message = "At least one `mailto:` endpoint must be provided."
  }

  validation {
    condition = can([
      for loc in var.dmarc_rua : regex("^mailto:.+", loc)
    ])
    error_message = "All must start with `mailto:`."
  }
}

variable "dmarc_ruf" {
  type        = list(string)
  default     = []
  description = "Where failure/forensic DMARC reports about policy violations should be sent."

  validation {
    condition = can([
      for loc in var.dmarc_ruf : regex("^mailto:.+", loc)
    ])
    error_message = "All must start with `mailto:`."
  }
}

variable "dmarc_fo" {
  type        = string
  default     = "1:d:s"
  description = "Failure reporting options for DMARC (characters: `0`, `1`, `d`, `s`, separated by `:`)."

  validation {
    condition = alltrue([
      for v in split(":", var.dmarc_fo) : contains(["0", "1", "d", "s"], v)
    ])
    error_message = "Only `0`, `1`, `d`, and `s` are supported, separated by `:`."
  }
}

#
# Domain Keys (DKIM)
#

variable "domainkeys" {
  type = map(object({
    type  = string
    value = string
  }))
  default     = {}
  description = "Map of domain keys with name, record type (`TXT` or `CNAME`), and value."

  validation {
    condition = alltrue([
      for name, dk in var.domainkeys : trimspace(name) != ""
    ])
    error_message = "Domain key name cannot be empty."
  }

  validation {
    condition = alltrue([
      for name, dk in var.domainkeys :
      contains(["TXT", "CNAME"], upper(dk.type))
    ])
    error_message = "Domain key type must be `TXT` or `CNAME`."
  }

  validation {
    condition = alltrue([
      for name, dk in var.domainkeys : trimspace(dk.value) != ""
    ])
    error_message = "Domain key value cannot be empty."
  }
}
