module Enterprise::WebsiteBrandingService
  CONTEXT_DEV_ENDPOINT = 'https://api.context.dev/v1/brand/retrieve-by-email'.freeze

  def perform
    return super unless context_dev_enabled?

    response = fetch_brand
    process_response(response)
  rescue StandardError => e
    Rails.logger.error "[WebsiteBranding] Context.dev failed: #{e.message}"
    nil
  end

  private

  def context_dev_enabled?
    context_dev_api_key.present?
  end

  def context_dev_api_key
    InstallationConfig.find_by(name: 'CONTEXT_DEV_API_KEY')&.value
  end

  def fetch_brand
    HTTParty.get(
      CONTEXT_DEV_ENDPOINT,
      query: { email: @email },
      headers: {
        'Authorization' => "Bearer #{context_dev_api_key}",
        'Content-Type' => 'application/json'
      }
    )
  end

  def process_response(response)
    @http_status = response.code
    raise "API Error: #{response.message} (Status: #{response.code})" unless response.success?

    brand = response.parsed_response&.dig('brand')
    return nil if brand.blank?

    format_brand(brand)
  end

  def format_brand(brand)
    {
      domain: brand['domain'],
      title: brand['title'],
      description: brand['description'],
      slogan: brand['slogan'],
      phone: brand['phone'],
      address: brand['address'],
      colors: brand['colors'] || [],
      logos: brand['logos'] || [],
      socials: brand['socials'] || [],
      links: brand['links'],
      email: @email,
      industries: brand.dig('industries', 'eic') || [],
      stock: brand['stock'],
      is_nsfw: brand['is_nsfw'] || false
    }.deep_symbolize_keys
  end
end
