class AgentBots::WebhookJob < WebhookJob
  queue_as :high
  retry_on RestClient::TooManyRequests, RestClient::InternalServerError, wait: 3.seconds, attempts: 3 do |job, error|
    url, payload, webhook_type = job.arguments
    Webhooks::Trigger.new(url, payload, webhook_type || :agent_bot_webhook).handle_failure(error)
  end

  def perform(url, payload, webhook_type = :agent_bot_webhook)
    super(url, payload, webhook_type)
  end
end
