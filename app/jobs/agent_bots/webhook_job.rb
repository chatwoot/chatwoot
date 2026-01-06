class AgentBots::WebhookJob < WebhookJob
  queue_as :high

  def perform(url, payload, webhook_type = :agent_bot_webhook, idempotency_key = nil)
    super(url, payload, webhook_type, idempotency_key)
  end
end
