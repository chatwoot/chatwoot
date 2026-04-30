class Whatsapp::WebhookTeardownService
  def initialize(channel)
    @channel = channel
  end

  def perform
    return unless should_teardown_webhook?

    api_client = Whatsapp::FacebookApiClient.new(provider_config['api_key'])

    clear_phone_number_override(api_client)
    clear_legacy_waba_override(api_client)
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

  # The WABA-level override_callback_uri is shared across every phone number on
  # the WABA, so we must not clear it while any sibling channel still depends
  # on it. We use a persisted marker written by WebhookSetupService as ground
  # truth: a channel that has webhook_override_level == 'phone_number' in its
  # provider_config is using a phone-level override (which takes precedence
  # over the WABA-level value) and does not need the WABA fallback. Siblings
  # without that marker are treated as legacy / still dependent on the WABA
  # callback and block the clear. phone_number_id alone cannot distinguish
  # these cases because legacy embedded-signup channels also persist it.
  def clear_legacy_waba_override(api_client)
    waba_id = provider_config['business_account_id']
    return if waba_id.blank?
    return if waba_dependent_sibling_exists?(waba_id)

    api_client.clear_waba_callback_override(waba_id)
    Rails.logger.info "[WHATSAPP] Legacy WABA webhook override cleared for channel #{@channel.id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Legacy WABA webhook clear failed for channel #{@channel.id}: #{e.message}"
  end

  def waba_dependent_sibling_exists?(waba_id)
    Channel::Whatsapp
      .where.not(id: @channel.id)
      .exists?([
                 "provider_config ->> 'business_account_id' = ? AND " \
                 "COALESCE(provider_config ->> 'webhook_override_level', '') <> 'phone_number'",
                 waba_id
               ])
  end
end
