module Enterprise::WebsiteBrandingService
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

  def perform
    return super unless firecrawl_enabled?

    response = perform_firecrawl_request
    process_firecrawl_response(response)
  rescue StandardError => e
    Rails.logger.error "[WebsiteBranding] Firecrawl failed: #{e.message}, falling back to basic scrape"
    super
  end

  private

  def firecrawl_enabled?
    firecrawl_api_key.present?
  end

  def firecrawl_api_key
    InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value
  end

  def perform_firecrawl_request
    HTTParty.post(
      FIRECRAWL_SCRAPE_ENDPOINT,
      body: scrape_payload.to_json,
      headers: {
        'Authorization' => "Bearer #{firecrawl_api_key}",
        'Content-Type' => 'application/json'
      }
    )
  end

  def scrape_payload
    {
      url: @url,
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

  def extract_schema
    {
      type: 'object',
      properties: {
        business_name: { type: 'string', description: 'The name of the business or company' },
        language: { type: 'string', description: 'Primary language as ISO 639-1 code (e.g., en, es, fr)' },
        industry_category: { type: 'string', enum: INDUSTRY_CATEGORIES, description: 'Industry category for this business' }
      },
      required: %w[business_name]
    }
  end

  def process_firecrawl_response(response)
    raise "API Error: #{response.message} (Status: #{response.code})" unless response.success?

    format_firecrawl_response(response)
  end

  def format_firecrawl_response(response)
    data = response.parsed_response
    extract = data.dig('data', 'json') || {}
    brand = data.dig('data', 'branding') || {}
    links = data.dig('data', 'links') || []

    {
      business_name: extract['business_name'],
      language: extract['language'],
      industry_category: extract['industry_category'],
      social_handles: extract_social_from_links(links),
      branding: extract_firecrawl_branding(brand)
    }
  end

  def extract_firecrawl_branding(brand)
    {
      favicon: url_or_nil(brand.dig('images', 'favicon')),
      primary_color: brand.dig('colors', 'primary')
    }
  end

  def url_or_nil(value)
    return nil if value.blank? || !value.start_with?('http')

    value
  end
end
