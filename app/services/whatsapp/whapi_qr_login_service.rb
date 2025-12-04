# frozen_string_literal: true

class Whatsapp::WhapiQrLoginService
  def initialize(channel:)
    @channel = channel
  end

  def perform
    Rails.logger.info '[WHATSAPP_LIGHT] Starting QR code fetch'
    validate_parameters!
    fetch_qr_code
  end

  private

  def validate_parameters!
    Rails.logger.info '[WHATSAPP_LIGHT] Validating QR login parameters'
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'Channel must be whatsapp_light provider' unless @channel.provider == 'whatsapp_light'
    raise ArgumentError, 'Channel ID not found in provider_config' if @channel.provider_config['channel_id'].blank?
    raise ArgumentError, 'Token not found in provider_config' if @channel.provider_config['token'].blank?

    Rails.logger.info "[WHATSAPP_LIGHT] QR login parameters validated. Channel ID: #{@channel.provider_config['channel_id']}"
  end

  def fetch_qr_code
    url = "#{api_base_url}/users/login"
    params = {
      wakeup: true,
      size: 100,
      channelId: @channel.provider_config['channel_id']
    }

    Rails.logger.info "[WHATSAPP_LIGHT] Fetching QR code from: #{url}"
    Rails.logger.info "[WHATSAPP_LIGHT] Query params: #{params.inspect}"

    response = HTTParty.get(
      url,
      headers: api_headers,
      query: params
    )

    Rails.logger.info "[WHATSAPP_LIGHT] QR fetch response status: #{response.code}"

    unless response.success?
      error_message = response.parsed_response&.dig('message') || 'Failed to fetch QR code'
      Rails.logger.error "[WHATSAPP_LIGHT] QR code fetch failed: #{error_message}"
      Rails.logger.error "[WHATSAPP_LIGHT] Response body: #{response.body}"
      raise "Whapi QR code fetch failed: #{error_message}"
    end

    parsed_response = response.parsed_response
    Rails.logger.info "[WHATSAPP_LIGHT] QR code fetched successfully. Status: #{parsed_response['status']}"

    {
      status: parsed_response['status'],
      expire: parsed_response['expire'],
      base64: parsed_response['base64']
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
