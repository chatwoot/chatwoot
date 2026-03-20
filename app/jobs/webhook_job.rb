class WebhookJob < ApplicationJob
  queue_as :medium

  retry_on CustomExceptions::Webhook::RetriableError, wait: :polynomially_longer, attempts: 5
  discard_on CustomExceptions::Webhook::RetriableError do |job, error|
    payload = job.arguments[1]
    webhook_type = job.arguments[2] || :account_webhook

    Rails.logger.warn "Webhook retries exhausted for #{payload[:event]}: #{error.message}"
    Webhooks::ErrorHandler.perform(payload, webhook_type, error)
  end

  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook)
    Webhooks::Trigger.execute(url, payload, webhook_type)
  end
end
