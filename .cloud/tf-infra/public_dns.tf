locals {
  acme_domain_names = flatten([
    for zone_name in concat([var.bunny_dns.zone_name], var.bunny_dns.additional_zone_names) : [
      "*.${zone_name}",
      zone_name,
    ]
  ])
}

resource "bunnynet_dns_zone" "public" {
  domain = var.bunny_dns.zone_name
}

resource "bunnynet_dns_zone" "additional" {
  for_each = toset(var.bunny_dns.additional_zone_names)
  domain   = each.value
}

resource "acme_registration" "reg" {
  email_address = var.bunny_dns.acme_email
}

resource "acme_certificate" "wildcard" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = local.acme_domain_names[0]
  subject_alternative_names = slice(local.acme_domain_names, 1, length(local.acme_domain_names))

  dns_challenge {
    provider = "bunny"
    config = {
      BUNNY_API_KEY = var.bunnynet_api_key
    }
  }

  depends_on = [
    bunnynet_dns_zone.public,
    bunnynet_dns_zone.additional,
  ]
}

resource "bunnynet_dns_record" "aca_wildcard" {
  zone  = bunnynet_dns_zone.public.id
  type  = "A"
  name  = "*"
  value = var.aca_private_endpoint_ip
  ttl   = 120
}

resource "bunnynet_dns_record" "aca_apex" {
  zone  = bunnynet_dns_zone.public.id
  type  = "A"
  name  = ""
  value = var.aca_private_endpoint_ip
  ttl   = 120
}

resource "bunnynet_dns_record" "aca_wildcard_additional_cname" {
  for_each = bunnynet_dns_zone.additional

  zone  = each.value.id
  type  = "CNAME"
  name  = "*"
  value = var.bunny_dns.zone_name
  ttl   = 120
}

resource "bunnynet_dns_record" "aca_apex_additional_cname" {
  for_each = bunnynet_dns_zone.additional

  zone  = each.value.id
  type  = "CNAME"
  name  = ""
  value = var.bunny_dns.zone_name
  ttl   = 120
}

output "bunnynet_zone_nameservers" {
  value = merge(
    {
      (bunnynet_dns_zone.public.domain) = {
        nameserver1 = bunnynet_dns_zone.public.nameserver1
        nameserver2 = bunnynet_dns_zone.public.nameserver2
      }
    },
    {
      for _, zone in bunnynet_dns_zone.additional :
      zone.domain => {
        nameserver1 = zone.nameserver1
        nameserver2 = zone.nameserver2
      }
    }
  )
}

output "acme_certificate_pem" {
  value     = acme_certificate.wildcard.certificate_pem
  sensitive = true
}

output "acme_issuer_pem" {
  value     = acme_certificate.wildcard.issuer_pem
  sensitive = true
}

output "acme_private_key_pem" {
  value     = acme_certificate.wildcard.private_key_pem
  sensitive = true
}

output "acme_certificate_p12" {
  value     = acme_certificate.wildcard.certificate_p12
  sensitive = true
}

output "acme_certificate_p12_password" {
  value     = acme_certificate.wildcard.certificate_p12_password
  sensitive = true
}
