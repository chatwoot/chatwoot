class Enterprise::WebsiteBrandingService
  FIRECRAWL_SCRAPE_ENDPOINT = 'https://api.firecrawl.dev/v2/scrape'.freeze

  INDUSTRY_CATEGORIES = [
    'Technology',
    'E-commerce',
    'Healthcare',
    'Education',
    'Finance',
    'Real Estate',
    'Marketing',
    'Travel & Hospitality',
    'Food & Beverage',
    'Media & Entertainment',
    'Professional Services',
    'Non-profit',
    'Other'
  ].freeze

  SOCIAL_DOMAIN_MAP = {
    whatsapp: %w[wa.me api.whatsapp.com],
    line: %w[line.me],
    facebook: %w[facebook.com fb.com fb.me],
    instagram: %w[instagram.com],
    telegram: %w[t.me telegram.me],
    tiktok: %w[tiktok.com]
  }.freeze

  def self.lookup(url)
    return nil unless firecrawl_enabled?

    normalized_url = normalize_url(url)
    response = perform_request(normalized_url)
    process_response(response)
  rescue StandardError => e
    Rails.logger.error "[WebsiteBranding] #{e.message}"
    nil
  end

  def self.firecrawl_enabled?
    firecrawl_api_key.present?
  end
  private_class_method :firecrawl_enabled?

  def self.firecrawl_api_key
    InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value
  end
  private_class_method :firecrawl_api_key

  def self.normalize_url(url)
    url.match?(%r{\Ahttps?://}) ? url : "https://#{url}"
  end
  private_class_method :normalize_url

  def self.perform_request(url)
    HTTParty.post(
      FIRECRAWL_SCRAPE_ENDPOINT,
      body: scrape_payload(url).to_json,
      headers: {
        'Authorization' => "Bearer #{firecrawl_api_key}",
        'Content-Type' => 'application/json'
      }
    )
  end
  private_class_method :perform_request

  def self.scrape_payload(url)
    {
      url: url,
      onlyMainContent: false,
      formats: [
        {
          type: 'json',
          schema: extract_schema,
          prompt: 'Extract the business name, primary language, and industry category from this website.'
        },
        'branding',
        'links'
      ]
    }
  end
  private_class_method :scrape_payload

  def self.extract_schema
    {
      type: 'object',
      properties: {
        business_name: { type: 'string', description: 'The name of the business or company' },
        language: { type: 'string', description: 'The primary language of the website as ISO 639-1 code (e.g., en, es, fr, de, ja)' },
        industry_category: {
          type: 'string',
          enum: INDUSTRY_CATEGORIES,
          description: 'The industry category that best describes this business'
        }
      },
      required: %w[business_name]
    }
  end
  private_class_method :extract_schema

  def self.process_response(response)
    return handle_error(response) unless response.success?

    format_response(response)
  end
  private_class_method :process_response

  def self.handle_error(response)
    Rails.logger.error "[WebsiteBranding] API Error: #{response.message} (Status: #{response.code})"
    nil
  end
  private_class_method :handle_error

  def self.format_response(response)
    data = response.parsed_response
    extract = data.dig('data', 'json') || {}
    brand = data.dig('data', 'branding') || {}
    links = data.dig('data', 'links') || []

    {
      business_name: extract['business_name'],
      language: extract['language'],
      industry_category: extract['industry_category'],
      social_handles: extract_social_from_links(links),
      branding: extract_branding(brand)
    }
  end
  private_class_method :format_response

  def self.extract_branding(brand)
    {
      logo: url_or_nil(brand.dig('images', 'logo')),
      favicon: url_or_nil(brand.dig('images', 'favicon')),
      primary_color: brand.dig('colors', 'primary')
    }
  end
  private_class_method :extract_branding

  def self.url_or_nil(value)
    return nil if value.blank? || !value.start_with?('http')

    value
  end
  private_class_method :url_or_nil

  def self.extract_social_from_links(links)
    handles = {}
    SOCIAL_DOMAIN_MAP.each do |platform, domains|
      link = links.find { |l| domains.any? { |d| match_domain?(URI.parse(l).host, d) } }
      handles[platform] = link ? parse_handle(platform, link) : nil
    rescue URI::InvalidURIError
      next
    end
    handles
  end
  private_class_method :extract_social_from_links

  def self.match_domain?(host, domain)
    return false if host.blank?

    host == domain || host.end_with?(".#{domain}")
  end
  private_class_method :match_domain?

  def self.parse_handle(platform, link)
    uri = URI.parse(link)
    return parse_whatsapp(uri) if platform == :whatsapp

    path = uri.path.to_s.delete_prefix('/').delete_suffix('/')
    path.presence
  rescue URI::InvalidURIError
    nil
  end

  # wa.me/1234567890 or api.whatsapp.com/send?phone=1234567890
  def self.parse_whatsapp(uri)
    phone = CGI.parse(uri.query.to_s)['phone']&.first
    phone = uri.path.to_s.delete_prefix('/').delete_suffix('/') if phone.blank?
    return nil if phone.blank?

    phone.gsub(/[^\d]/, '')
  end
  private_class_method :parse_whatsapp
  private_class_method :parse_handle
end
