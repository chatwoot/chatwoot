class WebhookJob < ApplicationJob
  queue_as :webhooks

  def perform(url, payload)
    Webhooks::Trigger.execute(url, payload)
  end
end
