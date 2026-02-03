class Moengage::CleanupOldEventLogsJob < ApplicationJob
  queue_as :low

  RETENTION_DAYS = 30

  def perform
    MoengageWebhookEventLog.where('created_at < ?', RETENTION_DAYS.days.ago)
                           .find_each(batch_size: 1000, &:delete)
  end
end
