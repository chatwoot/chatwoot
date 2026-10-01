# == Schema Information
#
# Table name: whatsapp_history_sync_events
#
class WhatsappHistorySyncEvent < ApplicationRecord
  belongs_to :history_sync, class_name: 'WhatsappHistorySync', foreign_key: :whatsapp_history_sync_id, inverse_of: :events

  enum status: { pending: 0, processing: 1, processed: 2, failed: 3 }

  validates :event_key, presence: true, uniqueness: { scope: :whatsapp_history_sync_id }
end
