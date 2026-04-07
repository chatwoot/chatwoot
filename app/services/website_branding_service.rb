class WebsiteBrandingService
  include SocialLinkParser

  def initialize(url)
    @url = normalize_url(url)
  end

  def perform
    doc = fetch_page
    return nil if doc.nil?

    links = extract_links(doc)

    {
      business_name: extract_business_name(doc),
      language: extract_language(doc),
      industry_category: nil,
      social_handles: extract_social_from_links(links),
      branding: extract_branding(doc)
    }
  rescue StandardError => e
    Rails.logger.error "[WebsiteBranding] #{e.message}"
    nil
  end

  private

  def normalize_url(url)
    url.match?(%r{\Ahttps?://}) ? url : "https://#{url}"
  end

  def fetch_page
    response = HTTParty.get(@url, follow_redirects: true, timeout: 15)
    return nil unless response.success?

    Nokogiri::HTML(response.body)
  rescue StandardError => e
    Rails.logger.error "[WebsiteBranding] Failed to fetch #{@url}: #{e.message}"
    nil
  end

  def extract_business_name(doc)
    og_site_name = doc.at_css('meta[property="og:site_name"]')&.[]('content')
    return og_site_name.strip if og_site_name.present?

    title = doc.at_xpath('//title')&.text
    title&.strip&.split(/\s*[|\-–—·:]+\s*/)&.first
  end

  def extract_language(doc)
    doc.at_css('html')&.[]('lang')&.split('-')&.first&.downcase
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

  def extract_branding(doc)
    {
      favicon: extract_favicon(doc),
      primary_color: extract_theme_color(doc)
    }
  end

  def extract_favicon(doc)
    favicon = doc.at_css('link[rel*="icon"]')&.[]('href')
    return nil if favicon.blank?

    resolve_url(favicon)
  end

  def extract_theme_color(doc)
    doc.at_css('meta[name="theme-color"]')&.[]('content')
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
