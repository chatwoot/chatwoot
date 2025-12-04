# frozen_string_literal: true

class Whatsapp::WhapiHealthService
  AUTH_STATUS_CODE = 4

  def initialize(channel:)
    @channel = channel
  end

  def perform
    Rails.logger.info "[WHATSAPP_LIGHT] Health check: Starting"
    validate_parameters!
    fetch_health_status
  end

  def authenticated?
    Rails.logger.info "[WHATSAPP_LIGHT] Health check: Checking authentication status"
    health_data = perform
    is_auth = health_data[:status_code] == AUTH_STATUS_CODE
    Rails.logger.info "[WHATSAPP_LIGHT] Health check: Authenticated = #{is_auth}, Status code = #{health_data[:status_code]}"
    is_auth
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_LIGHT] Health check failed: #{e.message}"
    false
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'Channel must be whatsapp_light provider' unless @channel.provider == 'whatsapp_light'
    raise ArgumentError, 'Token not found in provider_config' if @channel.provider_config['token'].blank?
  end

  def fetch_health_status
    url = "#{api_base_url}/health"
    Rails.logger.info "[WHATSAPP_LIGHT] Health check: Fetching from #{url}"

    response = HTTParty.get(
      url,
      headers: api_headers,
      query: {
        wakeup: true,
        platform: '<string>',
        channel_type: 'web'
      }
    )

    Rails.logger.info "[WHATSAPP_LIGHT] Health check: Response status #{response.code}"

    unless response.success?
      error_message = response.parsed_response&.dig('message') || 'Failed to fetch health status'
      Rails.logger.error "[WHATSAPP_LIGHT] Health check failed: #{error_message}"
      Rails.logger.error "[WHATSAPP_LIGHT] Response body: #{response.body}"
      raise "Whapi health check failed: #{error_message}"
    end

    parsed_response = response.parsed_response

    {
      status_code: parsed_response.dig('status', 'code'),
      status_text: parsed_response.dig('status', 'text'),
      full_response: parsed_response
    }
  end

  def api_headers
    {
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{@channel.provider_config['token']}"
    }
  end

  def api_base_url
    url = @channel.provider_config['api_url'] || ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')
    url.chomp('/')
  end
end
