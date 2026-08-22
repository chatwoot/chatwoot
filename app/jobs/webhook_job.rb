class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 2 types of webhooks, account and inbox
  def perform(url, payload, webhook_type = :account_webhook, secret: nil, delivery_id: nil)
    Webhooks::Trigger.execute(url, payload, webhook_type, secret: secret, delivery_id: delivery_id)
  end
end
