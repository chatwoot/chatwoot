class Whatsapp::WebhookTeardownService
  def initialize(channel)
    @channel = channel
  end

  def perform
    return unless should_teardown_webhook?

    api_client = Whatsapp::FacebookApiClient.new(provider_config['api_key'])

    clear_phone_number_override(api_client)
    unsubscribe_app_if_last_inbox(api_client)
  rescue StandardError => e
    # before_destroy must never block a channel delete — log and move on.
    Rails.logger.error "[WHATSAPP] Webhook teardown failed for channel #{@channel&.id}: #{e.message}"
  end

  private

  def provider_config
    @channel.provider_config || {}
  end

  def should_teardown_webhook?
    @channel.provider == 'whatsapp_cloud' &&
      provider_config['source'] == 'embedded_signup' &&
      provider_config['api_key'].present? &&
      (provider_config['phone_number_id'].present? || provider_config['business_account_id'].present?)
  end

  def clear_phone_number_override(api_client)
    phone_number_id = provider_config['phone_number_id']
    return if phone_number_id.blank?

    api_client.clear_phone_number_callback_override(phone_number_id)
    Rails.logger.info "[WHATSAPP] Phone-level webhook override cleared for channel #{@channel.id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Phone-level webhook clear failed for channel #{@channel.id}: #{e.message}"
  end

  # The app subscription is shared by every inbox on the WABA, so only unsubscribe when this is the last one.
  def unsubscribe_app_if_last_inbox(api_client)
    waba_id = provider_config['business_account_id']
    return if waba_id.blank?
    return if waba_sibling_exists?(waba_id)

    api_client.unsubscribe_app_from_waba(waba_id)
    Rails.logger.info "[WHATSAPP] WABA app subscription removed for channel #{@channel.id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] WABA app unsubscribe failed for channel #{@channel.id}: #{e.message}"
  end

  def waba_sibling_exists?(waba_id)
    Channel::Whatsapp
      .where.not(id: @channel.id)
      .exists?(["provider_config ->> 'business_account_id' = ?", waba_id])
  end
end
