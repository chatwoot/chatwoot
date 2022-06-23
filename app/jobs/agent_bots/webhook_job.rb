class AgentBots::WebhookJob < WebhookJob
  queue_as :bots
end
