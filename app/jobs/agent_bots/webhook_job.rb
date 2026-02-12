class AgentBots::WebhookJob < WebhookJob
  RETRY_ATTEMPTS = 3

  queue_as :high
  retry_on RestClient::TooManyRequests, RestClient::InternalServerError, wait: 3.seconds, attempts: RETRY_ATTEMPTS do |job, error|
    url, payload, webhook_type = job.arguments
    Webhooks::Trigger.new(url, payload, webhook_type || :agent_bot_webhook).handle_failure(error)
  end

  def perform(url, payload, webhook_type = :agent_bot_webhook)
    super(url, payload, webhook_type)
  rescue RestClient::TooManyRequests, RestClient::InternalServerError => e
    Rails.logger.warn(
      "[AgentBots::WebhookJob] Retryable webhook failure for #{url}. " \
      "error=#{e.class.name} attempt=#{executions}/#{RETRY_ATTEMPTS}"
    )
    raise
  end
end
