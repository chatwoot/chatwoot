class AgentBotJob < WebhookJob
  queue_as :bots
end
