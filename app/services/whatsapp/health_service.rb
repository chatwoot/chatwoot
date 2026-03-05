class Whatsapp::HealthService
  BASE_URI = 'https://graph.facebook.com'.freeze

  def initialize(channel)
    @channel = channel
    @access_token = channel.provider_config['api_key']
    @api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  def fetch_health_status
    validate_channel!
    fetch_phone_health_data
  end

  def fetch_webhook_status
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'API key is missing' if @access_token.blank?

    waba_id = @channel.provider_config['business_account_id']
    raise ArgumentError, 'Business account ID is missing' if waba_id.blank?

    api_client = Whatsapp::FacebookApiClient.new(@access_token)
    webhook_config = api_client.fetch_waba_webhook_config(waba_id)

    configured = webhook_configured?(webhook_config)
    actual_url = extract_webhook_url(webhook_config)

    {
      webhook_configured: configured,
      webhook_url: actual_url,
      webhook_url_mismatch: configured && url_mismatch?(actual_url)
    }
  end

  private

  def validate_channel!
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'API key is missing' if @access_token.blank?
    raise ArgumentError, 'Phone number ID is missing' if @channel.provider_config['phone_number_id'].blank?
  end

  def fetch_phone_health_data
    phone_number_id = @channel.provider_config['phone_number_id']

    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/#{phone_number_id}",
      query: {
        fields: health_fields,
        access_token: @access_token
      }
    )

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP HEALTH] Error fetching health data: #{e.message}"
    raise e
  end

  def health_fields
    %w[
      quality_rating
      messaging_limit_tier
      code_verification_status
      account_mode
      display_phone_number
      name_status
      verified_name
      throughput
      last_onboarded_time
      platform_type
    ].join(',')
  end

  def handle_response(response)
    unless response.success?
      error_message = "WhatsApp API request failed: #{response.code} - #{response.body}"
      Rails.logger.error "[WHATSAPP HEALTH] #{error_message}"
      raise error_message
    end

    data = response.parsed_response
    format_health_response(data)
  end

  def format_health_response(response)
    {
      display_phone_number: response['display_phone_number'],
      verified_name: response['verified_name'],
      name_status: response['name_status'],
      quality_rating: response['quality_rating'],
      messaging_limit_tier: response['messaging_limit_tier'],
      account_mode: response['account_mode'],
      code_verification_status: response['code_verification_status'],
      throughput: response['throughput'],
      last_onboarded_time: response['last_onboarded_time'],
      platform_type: response['platform_type'],
      business_id: @channel.provider_config['business_account_id']
    }
  end

  def webhook_configured?(webhook_config)
    webhook_config.present? && webhook_config['data'].present?
  end

  def extract_webhook_url(webhook_config)
    return nil if webhook_config.blank? || webhook_config['data'].blank?

    webhook_config['data'].filter_map { |app| app['override_callback_uri'] }.first
  end

  def url_mismatch?(actual_url)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    return false if frontend_url.blank?

    expected_url = "#{frontend_url}/webhooks/whatsapp/#{@channel.phone_number}"
    actual_url != expected_url
  end
end
