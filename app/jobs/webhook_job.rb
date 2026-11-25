class WebhookJob < ApplicationJob
  queue_as :medium

  # ONE handler, on purpose. `retry_on` and `discard_on` are both built on `rescue_from`, which
  # appends handlers and then resolves them with `reverse_each`, so the LAST matching declaration
  # wins. Declared as two statements for the same exception class, the `discard_on` shadowed the
  # `retry_on` above it: the job was discarded on its first failure and the five attempts never ran.
  # `retry_on`'s own block already runs exactly when the attempts are exhausted, which is what the
  # separate `discard_on` was reaching for.
  retry_on CustomExceptions::Webhook::RetriableError, wait: :polynomially_longer, attempts: 5 do |job, error|
    payload = job.arguments[1]
    webhook_type = job.arguments[2] || :account_webhook

    Rails.logger.warn "Webhook retries exhausted for #{payload[:event]}: #{error.message}"
    Webhooks::ErrorHandler.perform(payload, webhook_type, error)
  end

  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook, secret: nil, delivery_id: nil)
    Webhooks::Trigger.execute(url, payload, webhook_type, secret: secret, delivery_id: delivery_id)
  end
end
