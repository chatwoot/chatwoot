class Integrations::Calendly::WebhookJob < ApplicationJob
  queue_as :default

  def perform(hook, event, payload_json, webhook_log_id = nil)
    payload = JSON.parse(payload_json)
    webhook_log = Integrations::WebhookLog.find_by(id: webhook_log_id)
    Integrations::Calendly::WebhookProcessorService.new(hook: hook, event: event, payload: payload, webhook_log: webhook_log).perform
  end
end
