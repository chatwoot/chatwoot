class WebhookJob < ApplicationJob
  queue_as :medium

  def perform(url, payload, webhook_type = :account_webhook)
    Webhooks::Trigger.execute(url, payload, webhook_type)
  end
end
