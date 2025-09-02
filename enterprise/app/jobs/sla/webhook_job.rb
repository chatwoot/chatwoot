class Sla::WebhookJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(webhook_url, payload)
    @webhook_url = webhook_url
    @payload = payload

    send_webhook_request
  end

  private

  def send_webhook_request
    response = Faraday.post(@webhook_url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['User-Agent'] = 'Chatwoot-SLA-Webhook/1.0'
      req.headers['X-Chatwoot-Signature'] = generate_signature(@payload.to_json)
      req.body = @payload.to_json
    end

    handle_response(response)
  rescue Faraday::ConnectionFailed => e
    Rails.logger.error "SLA Webhook connection failed for #{@webhook_url}: #{e.message}"
    raise e # Re-raise to trigger retry
  rescue Faraday::TimeoutError => e
    Rails.logger.error "SLA Webhook timeout for #{@webhook_url}: #{e.message}"
    raise e # Re-raise to trigger retry
  rescue => e
    Rails.logger.error "SLA Webhook failed for #{@webhook_url}: #{e.message}"
    raise e
  end

  def handle_response(response)
    if response.success?
      Rails.logger.info "SLA Webhook successfully sent to #{@webhook_url}"
    else
      Rails.logger.warn "SLA Webhook returned #{response.status} for #{@webhook_url}: #{response.body}"
      raise StandardError, "Webhook returned #{response.status}"
    end
  end

  def generate_signature(payload)
    return nil unless webhook_secret.present?
    
    OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, payload)
  end

  def webhook_secret
    ENV['CHATWOOT_WEBHOOK_SECRET']
  end
end