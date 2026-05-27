class WebsiteBrandingService
  include SocialLinkParser

  attr_reader :http_status

  DATA_DEFAULTS = { description: nil, slogan: nil, phone: nil, address: nil, links: nil, stock: nil, industries: [], is_nsfw: false }.freeze

  def initialize(email)
    @email = email
    @domain = email.split('@').last&.downcase&.strip
    @url = "https://#{@domain}"
    @http_status = nil
  end

  def perform
    doc = fetch_page
    return nil if doc.nil?

    links = extract_links(doc)

    DATA_DEFAULTS.merge({
                          domain: @domain,
                          title: extract_title(doc),
                          colors: extract_colors(doc),
                          logos: extract_logos(doc),
                          socials: build_socials(links),
                          email: @email
                        })
  rescue StandardError => e
    Rails.logger.error "[WebsiteBranding] #{e.message}"
    nil
  end

  private

  def fetch_page
    response = HTTParty.get(@url, follow_redirects: true, timeout: 15)
    @http_status = response.code
    return nil unless response.success?

    Nokogiri::HTML(response.body)
  rescue StandardError => e
    Rails.logger.error "[WebsiteBranding] Failed to fetch #{@url}: #{e.message}"
    nil
  end

  def extract_title(doc)
    og_site_name = doc.at_css('meta[property="og:site_name"]')&.[]('content')
    return og_site_name.strip if og_site_name.present?

    title = doc.at_xpath('//title')&.text
    title&.strip&.split(/\s*[|\-–—·:]+\s*/)&.first
  end

  def extract_colors(doc)
    color = doc.at_css('meta[name="theme-color"]')&.[]('content')
    return [] if color.blank?

    [{ hex: color, name: nil }]
  end

  def extract_logos(doc)
    favicon = doc.at_css('link[rel*="icon"]')&.[]('href')
    return [] if favicon.blank?

    url = resolve_url(favicon)
    return [] if url.blank?

    [{ url: url, type: nil, mode: nil, colors: [], resolution: { aspect_ratio: 1 } }]
  end

  def build_socials(links)
    handles = extract_social_from_links(links)
    handles.filter_map do |platform, handle|
      next if handle.blank?

      url = reconstruct_social_url(platform, handle)
      { type: platform.to_s, url: url }
    end
  end

  def reconstruct_social_url(platform, handle)
    base_urls = { whatsapp: 'https://wa.me/', line: 'https://line.me/', facebook: 'https://facebook.com/',
                  instagram: 'https://instagram.com/', telegram: 'https://t.me/', tiktok: 'https://tiktok.com/' }
    "#{base_urls[platform]}#{handle}"
  end

  def extract_links(doc)
    doc.css('a[href]').filter_map do |a|
      href = a['href']&.strip
      next if href.blank? || href.start_with?('#', 'javascript:', 'mailto:', 'tel:')

      href.start_with?('http') ? href : URI.join(@url, href).to_s
    rescue URI::InvalidURIError
      nil
    end.uniq
  end

  def resolve_url(url)
    return nil if url.blank?
    return url if url.start_with?('http')

    URI.join(@url, url).to_s
  rescue URI::InvalidURIError
    nil
  end
end

WebsiteBrandingService.prepend_mod_with('WebsiteBrandingService')
