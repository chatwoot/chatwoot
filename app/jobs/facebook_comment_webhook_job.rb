class FacebookCommentWebhookJob < ApplicationJob
  queue_as :default
  
  def perform(config_id, data)
    config = FacebookCommentConfig.find_by(id: config_id)
    return unless config&.active?
    
    # Gửi webhook đến URL của người dùng
    response = HTTParty.post(
      config.webhook_url,
      body: data.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'X-Chatwoot-Signature' => generate_signature(data, config),
        'X-Chatwoot-Event-Type' => 'facebook_comment'
      }
    )
    
    # Ghi log kết quả
    if response.success?
      Rails.logger.info "Successfully sent Facebook comment webhook to #{config.webhook_url}"
    else
      Rails.logger.error "Failed to send Facebook comment webhook to #{config.webhook_url}: #{response.code} - #{response.body}"
    end
  rescue => e
    Rails.logger.error "Error sending Facebook comment webhook: #{e.message}"
  end
  
  private
  
  def generate_signature(data, config)
    secret = config.additional_attributes['webhook_secret'] || ''
    payload = data.to_json
    OpenSSL::HMAC.hexdigest('sha256', secret, payload)
  end
end
