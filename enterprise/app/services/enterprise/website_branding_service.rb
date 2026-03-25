class Enterprise::WebsiteBrandingService
  FIRECRAWL_SCRAPE_ENDPOINT = 'https://api.firecrawl.dev/v2/scrape'.freeze

  INDUSTRY_CATEGORIES = [
    'Technology',
    'E-commerce',
    'Healthcare',
    'Education',
    'Finance',
    'Real Estate',
    'Travel & Hospitality',
    'Food & Beverage',
    'Media & Entertainment',
    'Professional Services',
    'Non-profit',
    'Other'
  ].freeze

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
      formats: [
        {
          type: 'json',
          schema: extract_schema,
          prompt: 'Extract business information from this website. Look in the header, footer, contact page, ' \
                  'and about sections for social media handles and contact information. ' \
                  'For social handles, extract just the handle/username, not the full URL.'
        },
        'branding'
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
        },
        whatsapp_number: { type: 'string', description: 'WhatsApp phone number including country code, if available' },
        line_handle: { type: 'string', description: 'LINE messaging handle or ID, if available' },
        facebook_handle: { type: 'string', description: 'Facebook page handle or username, if available' },
        instagram_handle: { type: 'string', description: 'Instagram handle or username, if available' },
        telegram_handle: { type: 'string', description: 'Telegram handle or username, if available' },
        tiktok_handle: { type: 'string', description: 'TikTok channel handle or username, if available' }
      },
      required: %w[business_name]
    }
  end
  private_class_method :extract_schema

  def self.process_response(response)
    return handle_error(response) unless response.success?

    data = response.parsed_response
    colors = data.dig('data', 'branding', 'colors')
    puts "[WebsiteBranding] Colors: #{colors.inspect}" if colors

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

    {
      business_name: extract['business_name'],
      language: extract['language'],
      industry_category: extract['industry_category'],
      social_handles: extract_social_handles(extract),
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

  def self.url_or_nil(value)
    return nil if value.blank? || !value.start_with?('http')

    value
  end
  private_class_method :extract_branding
  private_class_method :url_or_nil

  def self.extract_social_handles(extract)
    {
      whatsapp: extract['whatsapp_number'],
      line: extract['line_handle'],
      facebook: extract['facebook_handle'],
      instagram: extract['instagram_handle'],
      telegram: extract['telegram_handle'],
      tiktok: extract['tiktok_handle']
    }.transform_values(&:presence)
  end
  private_class_method :extract_social_handles
end
