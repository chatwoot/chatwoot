class Telegram::WebhookSetupService
  pattr_initialize [:channel]

  def perform
    return if expected_webhook_url.blank?

    re_register_webhook_if_stale
  end

  # Re-registering never throws; failures are logged so a transport hiccup
  # cannot take down the scheduled job. Returns whether the webhook is now
  # correctly registered.
  def re_register_webhook_if_stale
    webhook_info = fetch_webhook_info
    return true if webhook_info_matches?(webhook_info)

    register_webhook
  end

  private

  def expected_webhook_url
    "#{webhook_base_url}/webhooks/telegram/#{channel.bot_token}"
  end

  def webhook_base_url
    ENV.fetch('FRONTEND_URL', nil)
  end

  def fetch_webhook_info
    response = HTTParty.get("#{channel.telegram_api_url}/getWebhookInfo")
    return {} unless response.success?

    response.parsed_response['result'] || {}
  end

  # The webhook only needs repairing when it points somewhere other than the
  # current FRONTEND_URL (e.g. the domain changed, or setup was interrupted).
  # A last_error_message is not enough to act on: it reflects a delivery hiccup
  # that re-registering the same URL cannot fix.
  def webhook_info_matches?(webhook_info)
    webhook_info['url'] == expected_webhook_url
  end

  def register_webhook
    response = HTTParty.post(
      "#{channel.telegram_api_url}/setWebhook",
      body: { url: expected_webhook_url }
    )
    response.success?
  rescue StandardError => e
    Rails.logger.error("[TELEGRAM] Webhook registration failed for channel #{channel.id}: #{e.message}")
    false
  end
end
