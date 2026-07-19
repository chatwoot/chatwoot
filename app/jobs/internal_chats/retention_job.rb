class InternalChats::RetentionJob < ApplicationJob
  queue_as :purgable

  BATCH_SIZE = 5_000

  def perform
    days = ENV.fetch('INTERNAL_CHAT_RETENTION_DAYS', '30').to_i
    threshold = days.days.ago
    deleted = 0

    InternalMessage.where('created_at < ?', threshold).in_batches(of: BATCH_SIZE) do |batch|
      count = batch.delete_all
      deleted += count
    end

    Rails.logger.info("[INTERNAL_CHAT_RETENTION] deleted=#{deleted} threshold=#{threshold.iso8601} days=#{days}")
  end
end
