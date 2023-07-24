class WebhookJob < ApplicationJob
  queue_as :medium

  def perform(url, payload)
    Webhooks::Trigger.execute(url, payload)
  end
end
