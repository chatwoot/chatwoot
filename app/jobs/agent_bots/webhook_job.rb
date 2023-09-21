class AgentBots::WebhookJob < WebhookJob
  queue_as :high
end
