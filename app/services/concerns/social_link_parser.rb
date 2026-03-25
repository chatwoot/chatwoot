module SocialLinkParser
  extend ActiveSupport::Concern

  SOCIAL_DOMAIN_MAP = {
    whatsapp: %w[wa.me api.whatsapp.com],
    line: %w[line.me],
    facebook: %w[facebook.com fb.com fb.me],
    instagram: %w[instagram.com],
    telegram: %w[t.me telegram.me],
    tiktok: %w[tiktok.com]
  }.freeze

  private

  def extract_social_from_links(links)
    handles = {}
    SOCIAL_DOMAIN_MAP.each do |platform, domains|
      link = links.find do |l|
        uri = URI.parse(l)
        domains.any? { |d| match_social_domain?(uri.host, d) }
      rescue URI::InvalidURIError
        false
      end
      handles[platform] = link ? parse_social_handle(platform, link) : nil
    end
    handles
  end

  def match_social_domain?(host, domain)
    return false if host.blank?

    host == domain || host.end_with?(".#{domain}")
  end

  def parse_social_handle(platform, link)
    uri = URI.parse(link)
    return extract_whatsapp_phone(uri) if platform == :whatsapp

    uri.path.to_s.delete_prefix('/').delete_suffix('/').presence
  rescue URI::InvalidURIError
    nil
  end

  # wa.me/1234567890 or api.whatsapp.com/send?phone=1234567890
  def extract_whatsapp_phone(uri)
    phone = CGI.parse(uri.query.to_s)['phone']&.first
    phone = uri.path.to_s.delete_prefix('/').delete_suffix('/') if phone.blank?
    phone.presence&.gsub(/[^\d]/, '')
  end
end
