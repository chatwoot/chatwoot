class AgentBots::WebhookJob < WebhookJob
  queue_as :high
  retry_on RestClient::TooManyRequests, RestClient::InternalServerError, wait: 3.seconds, attempts: 3 do |job, error|
    url, payload, webhook_type = job.arguments
    kwargs = job.arguments.last.is_a?(Hash) ? job.arguments.last : {}
    Webhooks::Trigger.new(url, payload, webhook_type || :agent_bot_webhook, secret: kwargs[:secret],
                                                                            delivery_id: kwargs[:delivery_id]).handle_failure(error)
  end

  def perform(url, payload, webhook_type = :agent_bot_webhook, secret: nil, delivery_id: nil)
    super(url, payload, webhook_type, secret: secret, delivery_id: delivery_id)
  rescue RestClient::TooManyRequests, RestClient::InternalServerError => e
    Rails.logger.warn("[AgentBots::WebhookJob] attempt #{executions} failed #{e.class.name} payload=#{payload.to_json}")
    raise
  end
end
