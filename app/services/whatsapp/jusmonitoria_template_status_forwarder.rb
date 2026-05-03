class Whatsapp::JusmonitoriaTemplateStatusForwarder
  def initialize(payload)
    @payload = payload
  end

  def call
    unless configured?
      Rails.logger.warn('meta_template_status_forward_skipped missing_jusmonitoria_internal_webhook_config')
      return false
    end

    response = HTTParty.post(
      webhook_url,
      headers: request_headers,
      body: @payload.to_json
    )
    return true if response.success?

    raise "JusMonitorIA template status forward failed: #{response.code} #{response.body}"
  end

  private

  def configured?
    webhook_url.present? && webhook_token.present?
  end

  def webhook_url
    @webhook_url ||= GlobalConfigService.load('JUSMONITORIA_INTERNAL_WEBHOOK_URL', '')
  end

  def webhook_token
    @webhook_token ||= GlobalConfigService.load('JUSMONITORIA_INTERNAL_WEBHOOK_TOKEN', '')
  end

  def request_headers
    {
      'Content-Type' => 'application/json',
      'X-Internal-API-Key' => webhook_token
    }
  end
end
