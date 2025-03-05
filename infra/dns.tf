resource "cloudflare_dns_record" "service" {
  zone_id = local.cloudflare_zones["digitaltolk.net"]
  name    = var.chatwoot_domain
  content = module.service.lb_dns_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
