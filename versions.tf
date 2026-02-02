terraform {
  required_version = ">= 1.1"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 3.0, < 5.0"
    }
  }
}
