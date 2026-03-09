class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook)
    Rails.logger.info "[WEBHOOK_JOB] Starting webhook job"
    Rails.logger.info "[WEBHOOK_JOB] URL: #{url}"
    Rails.logger.info "[WEBHOOK_JOB] Type: #{webhook_type}"
    Rails.logger.info "[WEBHOOK_JOB] Event: #{payload[:event]}"
    Rails.logger.info "[WEBHOOK_JOB] Has ACCESS_TOKEN: #{payload.key?(:ACCESS_TOKEN)}"
    
    Webhooks::Trigger.execute(url, payload, webhook_type)
    
    Rails.logger.info "[WEBHOOK_JOB] Webhook job completed successfully"
  rescue => e
    Rails.logger.error "[WEBHOOK_JOB] Webhook job failed: #{e.message}"
    Rails.logger.error "[WEBHOOK_JOB] Backtrace: #{e.backtrace.first(3).join(', ')}"
    raise # Re-raise para que o Sidekiq possa tentar novamente se necessário
  end
end
