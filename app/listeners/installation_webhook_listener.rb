class InstallationWebhookListener < BaseListener
  def account_created(event)
    idempotency_key = generate_idempotency_key(__method__.to_s, account(event))
    payload = account(event).webhook_data.merge(
      event: __method__.to_s,
      users: users(event),
      idempotency_key: idempotency_key
    )
    deliver_webhook_payloads(payload, idempotency_key)
  end

  private

  def account(event)
    event.data[:account]
  end

  def users(event)
    account(event).administrators.map(&:webhook_data)
  end

  def deliver_webhook_payloads(payload, idempotency_key)
    # Deliver the installation event
    webhook_url = InstallationConfig.find_by(name: 'INSTALLATION_EVENTS_WEBHOOK_URL')&.value
    WebhookJob.perform_later(webhook_url, payload, :account_webhook, idempotency_key) if webhook_url
  end

  def generate_idempotency_key(event_name, resource)
    return SecureRandom.uuid unless resource.respond_to?(:id) && resource.respond_to?(:updated_at)

    Digest::SHA256.hexdigest("#{event_name}-#{resource.class.name}-#{resource.id}-#{resource.updated_at.to_i}")
  end
end
