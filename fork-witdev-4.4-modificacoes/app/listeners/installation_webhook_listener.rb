class InstallationWebhookListener < BaseListener
  def account_created(event)
    payload = account(event).webhook_data.merge(
      event: __method__.to_s,
      users: users(event)
    )
    deliver_webhook_payloads(payload)
  end

  private

  def account(event)
    event.data[:account]
  end

  def users(event)
    account(event).administrators.map(&:webhook_data)
  end

  def deliver_webhook_payloads(payload)
    # Deliver the installation event
    webhook_url = InstallationConfig.find_by(name: 'INSTALLATION_EVENTS_WEBHOOK_URL')&.value
    WebhookJob.perform_later(webhook_url, payload) if webhook_url
  end
end
