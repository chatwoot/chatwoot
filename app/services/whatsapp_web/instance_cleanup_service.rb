require 'cgi'

class WhatsappWeb::InstanceCleanupService
  INTEGRATION_TYPE = 'whatsapp_web'.freeze
  PHONE_DIGITS_LENGTH = 11
  NOOP_PATTERNS = ['does not exist', 'instance not found', 'not found'].freeze

  def initialize(channel:, logger: Rails.logger)
    @channel = channel
    @logger = logger
  end

  def perform
    return false unless whatsapp_web_integration?

    settings = whatsapp_web_settings
    instance_name = resolved_instance_name(settings)
    return false if instance_name.blank?

    response = connector_client(settings).delete("/instance/delete/#{CGI.escape(instance_name)}")
    normalized_response = normalize_noop_response(response)
    raise_if_connector_payload_error!(normalized_response)

    true
  rescue WhatsappWeb::ConnectorClient::RequestError => e
    return true if noop_error_message?(extract_error_message(e).downcase)

    log_cleanup_failure(instance_name, e.message)
    raise
  end

  private

  def whatsapp_web_integration?
    channel_attributes = @channel.additional_attributes.to_h.with_indifferent_access
    channel_attributes[:integration_type].to_s == INTEGRATION_TYPE
  end

  def whatsapp_web_settings
    channel_attributes = @channel.additional_attributes.to_h.with_indifferent_access
    (channel_attributes[:whatsapp_web] || {}).with_indifferent_access
  end

  def resolved_instance_name(settings)
    instance_name = settings[:instance_name].to_s.strip
    return instance_name if instance_name.present?

    phone = normalized_phone(settings[:phone])
    return '' if phone.blank?

    "cw_#{@channel.account_id}_#{phone}"
  end

  def normalized_phone(value)
    value.to_s.gsub(/\D/, '').slice(0, PHONE_DIGITS_LENGTH)
  end

  def connector_client(settings)
    WhatsappWeb::ConnectorClient.new(
      base_url: resolved_base_url(settings),
      base_path: resolved_base_path(settings),
      api_key: resolved_api_key(settings)
    )
  end

  def resolved_base_url(settings)
    stored = settings[:evolution_base_url].to_s.strip
    return stored if stored.present?

    [
      ENV.fetch('WHATSAPP_WEB_EVOLUTION_BASE_URL', '').to_s.strip,
      ENV.fetch('EVOLUTION_SERVER_URL', '').to_s.strip
    ].find(&:present?).to_s
  end

  def resolved_base_path(settings)
    stored = settings[:evolution_base_path].to_s.strip
    return stored if stored.present?

    ENV.fetch('WHATSAPP_WEB_EVOLUTION_BASE_PATH', '').to_s
  end

  def resolved_api_key(settings)
    stored = settings[:evolution_api_key].to_s.strip
    return stored if stored.present?

    [
      ENV.fetch('WHATSAPP_WEB_EVOLUTION_API_KEY', '').to_s.strip,
      ENV.fetch('EVOLUTION_AUTHENTICATION_API_KEY', '').to_s.strip,
      ENV.fetch('AUTHENTICATION_API_KEY', '').to_s.strip
    ].find(&:present?).to_s
  end

  def unwrap_results(response)
    return response unless response.is_a?(Hash)

    response['results'] || response
  end

  def connector_payload_error?(response)
    payload = unwrap_results(response)
    payload.is_a?(Hash) && payload.with_indifferent_access[:error] == true
  end

  def payload_error_message(response)
    payload = unwrap_results(response)
    return payload.to_s unless payload.is_a?(Hash)

    message = payload.with_indifferent_access[:message]
    return message.to_s if message.present?

    response_message = payload.with_indifferent_access.dig(:response, :message)
    return response_message.join(', ') if response_message.is_a?(Array) && response_message.any?
    return response_message.to_s if response_message.present?

    payload.with_indifferent_access[:error].to_s
  end

  def raise_if_connector_payload_error!(response)
    return unless connector_payload_error?(response)

    raise WhatsappWeb::ConnectorClient::RequestError.new(
      payload_error_message(response).presence || 'Connector request failed',
      response_body: unwrap_results(response)
    )
  end

  def normalize_noop_response(response)
    return response unless connector_payload_error?(response)

    message = payload_error_message(response).to_s.downcase
    return response unless noop_error_message?(message)

    successful_noop_response(payload_error_message(response))
  end

  def noop_error_message?(message)
    NOOP_PATTERNS.any? { |pattern| message.include?(pattern) }
  end

  def successful_noop_response(message)
    {
      'status' => 'SUCCESS',
      'error' => false,
      'response' => {
        'message' => message.to_s
      }
    }
  end

  def extract_error_message(error)
    body = error.respond_to?(:response_body) ? error.response_body : nil
    return body.to_s unless body.is_a?(Hash)

    payload = body.with_indifferent_access
    payload[:message].to_s.presence || payload[:error].to_s.presence || body.to_s
  end

  def log_cleanup_failure(instance_name, message)
    @logger.error(
      "[WHATSAPP_WEB] cleanup_failed account_id=#{@channel.account_id} channel_id=#{@channel.id} instance_name=#{instance_name} error=#{message}"
    )
  end
end
