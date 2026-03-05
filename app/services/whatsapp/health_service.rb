class Whatsapp::HealthService
  BASE_URI = 'https://graph.facebook.com'.freeze

  def initialize(channel)
    @channel = channel
    @access_token = channel.provider_config['api_key']
    @api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  def fetch_health_status
    validate_channel!
    phone_data = fetch_phone_health_data
    messaging_health = fetch_messaging_health_data
    phone_data.merge(messaging_health: messaging_health)
  end

  def fetch_webhook_status
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'API key is missing' if @access_token.blank?

    waba_id = @channel.provider_config['business_account_id']
    raise ArgumentError, 'Business account ID is missing' if waba_id.blank?

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

  def fetch_messaging_health_data
    phone_number_id = @channel.provider_config['phone_number_id']
    return nil if phone_number_id.blank?

    api_client = Whatsapp::FacebookApiClient.new(@access_token)
    response = api_client.fetch_phone_messaging_health(phone_number_id)
    parse_messaging_health(response)
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP HEALTH] Could not fetch messaging health: #{e.message}"
    nil
  end

  def parse_messaging_health(response)
    return nil if response.blank?

    {
      can_send_message: response['can_send_message'],
      entities: response['entities']&.map do |entity|
        {
          entity_type: entity['entity_type'],
          can_send_message: entity['can_send_message'],
          errors: entity['errors'],
          additional_info: entity['additional_info']
        }.compact
      end
    }.compact
  end

  def webhook_configured?(webhook_config)
    webhook_config.present? && webhook_config['data'].present?
  end

  def extract_webhook_url(webhook_config)
    return nil if webhook_config.blank? || webhook_config['data'].blank?

    webhook_config['data'].filter_map { |app| app['override_callback_uri'] }.first
  end
end
