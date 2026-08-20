# == Schema Information
#
# Table name: whatsapp_history_syncs
#
class WhatsappHistorySync < ApplicationRecord
  NO_DATA_RECEIVED_AFTER = 24.hours

  belongs_to :channel, class_name: 'Channel::Whatsapp', foreign_key: :whatsapp_channel_id, inverse_of: :whatsapp_history_sync
  has_many :events, class_name: 'WhatsappHistorySyncEvent', dependent: :destroy_async, inverse_of: :history_sync

  enum status: {
    requested: 0,
    receiving: 1,
    processing: 2,
    completed: 3,
    not_shared: 4,
    failed: 5
  }

  validates :progress, inclusion: { in: 0..100 }
  validates :whatsapp_channel_id, uniqueness: true

  after_commit :invalidate_inbox_cache

  def api_status
    return 'no_data_received' if requested? && first_event_at.blank? && updated_at < NO_DATA_RECEIVED_AFTER.ago

    status
  end

  def api_payload
    {
      status: api_status,
      progress: progress,
      imported_messages: imported_messages,
      imported_conversations: imported_conversations,
      request_id: request_id,
      started_at: started_at&.to_i,
      completed_at: completed_at&.to_i
    }.compact
  end

  private

  def invalidate_inbox_cache
    channel.account.update_cache_key('inbox')
  end
end
