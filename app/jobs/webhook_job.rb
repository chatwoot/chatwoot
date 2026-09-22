class WebhookJob < ApplicationJob
  queue_as :medium

  retry_on Webhooks::Trigger::RetryableError, wait: 3.seconds, attempts: 3 do |job, error|
    url, payload, *arguments = job.arguments
    options = arguments.extract_options!
    webhook_type = arguments.first || :account_webhook
    Webhooks::Trigger.new(url, payload, webhook_type, secret: options[:secret],
                                                    delivery_id: options[:delivery_id]).handle_failure(error)
  end

  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook, secret: nil, delivery_id: nil)
    Webhooks::Trigger.execute(url, payload, webhook_type, secret: secret, delivery_id: delivery_id)
  end
end
