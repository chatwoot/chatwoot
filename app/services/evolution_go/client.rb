require 'openssl'

class EvolutionGo::Client
  REQUEST_TIMEOUT = 10
  SUBSCRIPTIONS = %w[MESSAGE READ_RECEIPT CONNECTION QRCODE].freeze

  class Error < StandardError; end
  class ConfigurationError < Error; end

  pattr_initialize [:channel!]

  class << self
    def base_url
      ENV.fetch('EVOLUTION_GO_BASE_URL', 'http://evolution-go:8080').to_s.chomp('/')
    end

    def global_api_key
      ENV['EVOLUTION_GO_GLOBAL_API_KEY'].to_s
    end

    def configured?
      base_url.present? && global_api_key.present?
    end

    def instance_token(instance_name)
      raise ConfigurationError, 'Evolution Go global API key is not configured' if global_api_key.blank?
      raise ConfigurationError, 'Evolution Go instance name is not configured' if instance_name.blank?

      OpenSSL::HMAC.hexdigest('SHA256', global_api_key, "chatwit:evolution_go:#{instance_name}")
    end
  end

  def available?
    return false unless self.class.configured?

    response = HTTParty.get(url('/server/ok'), timeout: REQUEST_TIMEOUT)
    response.success? && parsed_body(response)['status'] == 'ok'
  rescue StandardError => e
    Rails.logger.error "[EVOLUTION_GO] Availability check failed: #{e.message}"
    false
  end

  def ensure_instance!
    create_instance if find_instance_by_name.blank?
    connect_instance
  rescue Error => e
    raise unless e.message.to_s.downcase.include?('already')
  end

  def create_instance
    post_admin('/instance/create', body: { name: instance_name, token: instance_token })
  end

  def connect_instance(webhook_url: callback_webhook_url, subscribe: SUBSCRIPTIONS)
    post_instance('/instance/connect', body: { webhookUrl: webhook_url, subscribe: subscribe, immediate: true })
  end

  def list_instances
    get_admin('/instance/all')
  end

  def find_instance_by_name
    list_instances.find { |instance| instance['name'] == instance_name }
  end

  def fetch_status
    get_instance('/instance/status')
  end

  def fetch_qr_code
    get_instance('/instance/qr')
  end

  def delete_instance
    instance_id = find_instance_by_name&.dig('id')
    return if instance_id.blank?

    delete_admin("/instance/delete/#{instance_id}")
  end

  def send_text(number:, text:, quoted_message_id: nil)
    post_instance('/send/text', body: build_text_body(number: number, text: text, quoted_message_id: quoted_message_id))
  end

  def send_media(number:, attachment:, caption: nil, quoted_message_id: nil)
    body = {
      number: normalize_number(number),
      url: attachment.download_url,
      type: media_type_for(attachment),
      quoted: build_quoted_payload(quoted_message_id)
    }
    body[:caption] = caption if caption.present? && !attachment.audio?
    body[:filename] = attachment.file.filename.to_s if attachment.file?

    post_instance('/send/media', body: body.compact)
  end

  def url(path)
    "#{self.class.base_url}#{path}"
  end

  def instance_token
    self.class.instance_token(instance_name)
  end

  private

  def instance_name
    channel.provider_config.to_h['instance_name']
  end

  def callback_webhook_url
    frontend_url = ENV['FRONTEND_URL'].to_s
    raise ConfigurationError, 'FRONTEND_URL is not configured' if frontend_url.blank?

    "#{frontend_url}/webhooks/evolution_go"
  end

  def build_text_body(number:, text:, quoted_message_id:)
    {
      number: normalize_number(number),
      text: text,
      quoted: build_quoted_payload(quoted_message_id)
    }.compact
  end

  def build_quoted_payload(quoted_message_id)
    return if quoted_message_id.blank?

    { messageId: quoted_message_id }
  end

  def normalize_number(number)
    number.to_s.gsub(/\D/, '')
  end

  def media_type_for(attachment)
    return attachment.file_type if %w[image audio video].include?(attachment.file_type)

    'document'
  end

  def get_admin(path)
    response = HTTParty.get(url(path), headers: admin_headers, timeout: REQUEST_TIMEOUT)
    extract_data(response)
  end

  def get_instance(path)
    response = HTTParty.get(url(path), headers: instance_headers, timeout: REQUEST_TIMEOUT)
    extract_data(response)
  end

  def post_admin(path, body:)
    response = HTTParty.post(url(path), headers: json_headers(admin_headers), body: body.to_json, timeout: REQUEST_TIMEOUT)
    extract_data(response)
  end

  def post_instance(path, body:)
    response = HTTParty.post(url(path), headers: json_headers(instance_headers), body: body.to_json, timeout: REQUEST_TIMEOUT)
    extract_data(response)
  end

  def delete_admin(path)
    response = HTTParty.delete(url(path), headers: admin_headers, timeout: REQUEST_TIMEOUT)
    extract_data(response)
  end

  def extract_data(response)
    body = parsed_body(response)
    return body['data'] if response.success?

    raise Error, error_message(response, body)
  end

  def parsed_body(response)
    parsed = response.parsed_response
    parsed.is_a?(Hash) ? parsed : {}
  end

  def error_message(response, body)
    body['error'].presence || body['message'].presence || "Evolution Go request failed with status #{response.code}"
  end

  def admin_headers
    { 'apikey' => self.class.global_api_key }
  end

  def instance_headers
    { 'apikey' => instance_token }
  end

  def json_headers(headers)
    headers.merge('Content-Type' => 'application/json')
  end
end
