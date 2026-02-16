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
    validate_channel!
    waba_id = @channel.provider_config['business_account_id']
    api_client = Whatsapp::FacebookApiClient.new(@access_token)
    webhook_config = api_client.fetch_waba_webhook_config(waba_id)

    {
      webhook_configured: webhook_configured?(webhook_config),
      webhook_url: extract_webhook_url(webhook_config)
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
      id
      display_phone_number
      name_status
      verified_name
      webhook_configuration
      throughput
      last_onboarded_time
      platform_type
      certificate
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
    return false if webhook_config.blank? || webhook_config['data'].blank?

    webhook_config['data'].any? do |app|
      app['subscribed_fields']&.include?('messages')
    end
  end

  def extract_webhook_url(webhook_config)
    return nil if webhook_config.blank? || webhook_config['data'].blank?

    app_with_webhook = webhook_config['data'].find do |app|
      app['subscribed_fields']&.include?('messages')
    end

    app_with_webhook&.dig('whatsapp_business_api_data', 'callback_url')
  end
end
