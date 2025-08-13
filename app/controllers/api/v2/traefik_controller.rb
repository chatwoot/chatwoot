class Api::V2::TraefikController < Api::BaseController
  def config
    domains = Portal.where.not(custom_domain: ['']).pluck(:custom_domain)
    helpcenter_url = ENV.fetch('HELPCENTER_URL', '')
    frontend_url = ENV.fetch('FRONTEND_URL', '')

    domains << extract_hostname(helpcenter_url) if helpcenter_url.present?
    domains << extract_hostname(frontend_url) if frontend_url.present?
    domains.uniq!
    
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

  private

  # Extracted from app/mailers/portal_instructions_mailer.rb
  def extract_hostname(url)
    uri = URI.parse(url)
    uri.host
  rescue URI::InvalidURIError
    url.gsub(%r{https?://}, '').split('/').first
  end
end
