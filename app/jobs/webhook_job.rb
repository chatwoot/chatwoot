class WebhookJob < ApplicationJob
  queue_as :medium

  #  There are 3 types of webhooks, account, inbox and agent_bot

  retry_on StandardError, wait: ->(executions) { 2**(executions - 1) }, attempts: 3 do |_job, error|
    url, payload, webhook_type = arguments
    type = (webhook_type || 'account_webhook').to_sym
    Webhooks::Trigger.new(url, payload, type).handle_error(error)
  end

  def perform(url, payload, webhook_type = :account_webhook, secret: nil, delivery_id: nil)
    Webhooks::Trigger.execute(url, payload, webhook_type, secret: secret, delivery_id: delivery_id)
  end
end
