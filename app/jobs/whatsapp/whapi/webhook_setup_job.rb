class Whatsapp::Whapi::WebhookSetupJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(channel_id)
    channel = Channel::Whatsapp.find_by(id: channel_id)
    return unless channel&.provider == 'whapi'

    config_object = channel.provider_config_object
    channel_token = config_object.whapi_channel_token
    return if channel_token.blank?

    webhook_service = Whatsapp::WebhookUrlService.new
    webhook_url = webhook_service.generate_webhook_url
    
    service = Whatsapp::Partner::WhapiPartnerService.new
    service.update_channel_webhook(channel_token: channel_token, webhook_url: webhook_url)
    
    # Mark webhook as configured successfully
    config_object.set_webhook_configured(webhook_url)
    
    Rails.logger.info "[WhapiWebhookSetup] Webhook configured successfully for channel #{channel_id}"
  rescue Net::TimeoutError, Net::OpenTimeout => e
    Rails.logger.warn "[WhapiWebhookSetup] Webhook setup timeout for channel #{channel_id}: #{e.message}"
    config_object&.set_webhook_failed("Timeout: #{e.message}")
    raise
  rescue HTTParty::Error, Net::HTTPError => e
    Rails.logger.error "[WhapiWebhookSetup] Webhook setup HTTP error for channel #{channel_id}: #{e.message}"
    config_object&.set_webhook_failed("HTTP Error: #{e.message}")
    raise
  rescue JSON::ParserError => e
    Rails.logger.error "[WhapiWebhookSetup] Webhook setup JSON parse error for channel #{channel_id}: #{e.message}"
    config_object&.set_webhook_failed("JSON Parse Error: #{e.message}")
    raise
  rescue StandardError => e
    Rails.logger.error "[WhapiWebhookSetup] Unexpected webhook setup error for channel #{channel_id}: #{e.class} - #{e.message}"
    config_object&.set_webhook_failed("Unknown Error: #{e.message}")
    raise
  end
end
