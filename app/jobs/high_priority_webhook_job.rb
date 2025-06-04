class HighPriorityWebhookJob < ApplicationJob
  queue_as :critical
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook)
    Webhooks::Trigger.execute(url, payload, webhook_type)
  end
end
