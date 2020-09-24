class InstallationWebhookListener < BaseListener
  def account_created(event)
    payload = event.data[:account].webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload)
  end

  def account_destroyed(event)
    payload = event.data[:account].webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload)
  end

  private

  def deliver_webhook_payloads(payload)
    # Deliver the installation event
    webhook_url = InstallationConfig.find_by(name: 'INSTALLATION_EVENTS_WEBHOOK_URL')&.value
    WebhookJob.perform_later(webhook_url, payload) if webhook_url
  end
end
