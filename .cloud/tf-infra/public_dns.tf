resource "bunnynet_dns_zone" "public" {
  domain = var.bunny_dns.zone_name
}

resource "acme_registration" "reg" {
  email_address = var.bunny_dns.acme_email
}

resource "acme_certificate" "wildcard" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "*.${var.bunny_dns.zone_name}"
  subject_alternative_names = [var.bunny_dns.zone_name]

  dns_challenge {
    provider = "bunny"
    config = {
      BUNNY_API_KEY = var.bunnynet_api_key
    }
  }

  depends_on = [bunnynet_dns_zone.public]
}

resource "bunnynet_dns_record" "aca_wildcard" {
  zone  = bunnynet_dns_zone.public.id
  type  = "A"
  name  = "*"
  value = var.aca_private_endpoint_ip
  ttl   = 120
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
