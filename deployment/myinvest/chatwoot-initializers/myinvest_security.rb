# frozen_string_literal: true

# Chatwoot's signed AgentBot jobs carry the webhook secret as an internal job
# argument. Keep Active Job arguments out of production logs.
ActiveJob::Base.log_arguments = false

Rails.application.config.after_initialize do
  AgentBots::WebhookJob.class_eval do
    define_method(:perform) do |url, payload, webhook_type = :agent_bot_webhook, secret: nil, delivery_id: nil|
      Webhooks::Trigger.execute(
        url, payload, webhook_type, secret: secret, delivery_id: delivery_id
      )
    rescue Webhooks::Trigger::RetryableError => error
      Rails.logger.warn(
        "[AgentBots::WebhookJob] attempt #{executions} failed #{error.class.name}"
      )
      raise
    end
  end
end
