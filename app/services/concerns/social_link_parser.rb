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
      handles[platform] = find_social_handle(links, platform, domains)
    end
    handles
  end

  def find_social_handle(links, platform, domains)
    matching_links = links.select do |l|
      uri = URI.parse(l)
      domains.any? { |d| match_social_domain?(uri.host, d) }
    rescue URI::InvalidURIError
      false
    end

    matching_links.each do |link|
      handle = parse_social_handle(platform, link)
      return handle if handle.present?
    end
    nil
  end

  def match_social_domain?(host, domain)
    return false if host.blank?

    host == domain || host.end_with?(".#{domain}")
  end

  SHARE_PATH_PREFIXES = %w[sharer share intent dialog].freeze

  def parse_social_handle(platform, link)
    uri = URI.parse(link)
    return extract_whatsapp_phone(uri) if platform == :whatsapp

    handle = uri.path.to_s.delete_prefix('/').delete_suffix('/')
    return nil if handle.blank?
    return nil if SHARE_PATH_PREFIXES.any? { |prefix| handle.start_with?(prefix) }

    handle.presence
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
