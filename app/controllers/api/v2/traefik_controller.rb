class Api::V2::TraefikController < Api::BaseController
  def config
    domains = Portal.where.not(custom_domain: ['']).pluck(:custom_domain)
    rule = domains.map { |domain| "Host(`#{domain}`)" }.join(' || ')

    render json: {
      http: {
        routers: {
          chatwoot_rails: {
            rule: rule,
            service: 'chatwoot_rails',
            entryPoints: ['websecure'],
            tls: {
              certResolver: 'letsencrypt' # TODO: maybe provide a way for users to change this?
            }
          }
        }
      }
    }
  end
end
