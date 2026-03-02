class Integrations::Calendly::WebhookJob < ApplicationJob
  queue_as :default

  def perform(hook, event, payload_json)
    payload = JSON.parse(payload_json)
    Integrations::Calendly::WebhookProcessorService.new(hook: hook, event: event, payload: payload).perform
  end
end
