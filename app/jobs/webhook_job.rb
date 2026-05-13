class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook, secret: nil, delivery_id: nil, additional_headers: nil)
    Webhooks::Trigger.execute(url, payload, webhook_type, secret: secret, delivery_id: delivery_id, additional_headers: additional_headers)
  end
end
