class Whatsapp::WebhookTeardownService
  def initialize(channel)
    @channel = channel
  end

  def perform
    return unless should_teardown_webhook?

    teardown_webhook
  rescue StandardError => e
    handle_webhook_teardown_error(e)
  end

  private

  def should_teardown_webhook?
    whatsapp_cloud_provider? && embedded_signup_source? && webhook_config_present?
  end

  def whatsapp_cloud_provider?
    @channel.provider == 'whatsapp_cloud'
  end

  def embedded_signup_source?
    @channel.provider_config['source'] == 'embedded_signup'
  end

  def webhook_config_present?
    @channel.provider_config['phone_number_id'].present? &&
      @channel.provider_config['api_key'].present?
  end

  def teardown_webhook
    phone_number_id = @channel.provider_config['phone_number_id']
    access_token = @channel.provider_config['api_key']
    api_client = Whatsapp::FacebookApiClient.new(access_token)

    api_client.clear_phone_number_callback_override(phone_number_id)
    Rails.logger.info "[WHATSAPP] Phone number webhook override cleared for channel #{@channel.id}"
  end

  def handle_webhook_teardown_error(error)
    Rails.logger.error "[WHATSAPP] Webhook teardown failed: #{error.message}"
    # Don't raise the error to prevent channel deletion from failing
    # Failed webhook teardown shouldn't block deletion
  end
end
