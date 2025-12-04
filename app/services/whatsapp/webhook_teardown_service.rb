class Whatsapp::WebhookTeardownService
  def initialize(channel)
    @channel = channel
  end

  def perform
    if whatsapp_light_provider?
      teardown_whapi_channel
    elsif should_teardown_webhook?
      teardown_webhook
    end
  rescue StandardError => e
    handle_webhook_teardown_error(e)
  end

  private

  def whatsapp_light_provider?
    @channel.provider == 'whatsapp_light'
  end

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
    @channel.provider_config['business_account_id'].present? &&
      @channel.provider_config['api_key'].present?
  end

  def teardown_webhook
    waba_id = @channel.provider_config['business_account_id']
    access_token = @channel.provider_config['api_key']
    api_client = Whatsapp::FacebookApiClient.new(access_token)

    api_client.unsubscribe_waba_webhook(waba_id)
    Rails.logger.info "[WHATSAPP] Webhook unsubscribed successfully for channel #{@channel.id}"
  end

  def teardown_whapi_channel
    channel_id = @channel.provider_config['channel_id']
    token = @channel.provider_config['token']

    return unless channel_id.present? && token.present?

    whapi_manager_url = ENV.fetch('WHAPI_MANAGER_URL', 'https://manager.whapi.cloud')
    url = "#{whapi_manager_url}/channels/#{channel_id}"

    response = HTTParty.delete(
      url,
      headers: {
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    )

    if response.success?
      Rails.logger.info "[WHATSAPP LIGHT] Channel #{channel_id} deleted successfully from Whapi"
    else
      Rails.logger.error "[WHATSAPP LIGHT] Failed to delete channel #{channel_id}: #{response.code} - #{response.body}"
    end
  end

  def handle_webhook_teardown_error(error)
    Rails.logger.error "[WHATSAPP] Webhook teardown failed: #{error.message}"
    # Don't raise the error to prevent channel deletion from failing
    # Failed webhook teardown shouldn't block deletion
  end
end
