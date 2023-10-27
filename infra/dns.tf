resource "cloudflare_record" "handesk-digitaltolk-net" {
  zone_id = data.cloudflare_zone.digitaltolknet.zone_id
  name    = var.chatwoot_domain
  value   = module.service.lb_dns_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}
