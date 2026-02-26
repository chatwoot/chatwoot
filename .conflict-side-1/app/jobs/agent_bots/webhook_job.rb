class AgentBots::WebhookJob < WebhookJob
  queue_as :high

  def perform(url, payload, webhook_type = :agent_bot_webhook)
    super(url, payload, webhook_type)
  end
end
