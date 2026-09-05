# cat-fork: account-level chat queue and concurrent-chat limit settings.
# See ChatQueue::* services and Queue::ProcessQueueJob.
module AccountChatQueue
  extend ActiveSupport::Concern

  included do
    has_many :conversation_queues, dependent: :destroy_async
    has_many :queue_statistics, dependent: :destroy_async
    has_many :priority_groups, dependent: :destroy

    store_accessor :settings, :busy_to_offline_timeout
    store_accessor :settings, :agent_history_days

    validates :active_chat_limit_value, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

    after_commit :process_queue_when_limit_changed, if: :active_chat_limit_settings_changed?
  end

  def active_chat_limit_enabled?
    active_chat_limit_enabled
  end

  def active_chat_limit
    active_chat_limit_value
  end

  def active_chat_limit_settings_changed?
    saved_change_to_active_chat_limit_enabled? || saved_change_to_active_chat_limit_value?
  end

  def process_queue_when_limit_changed
    return unless queue_enabled?

    inboxes.pluck(:id).each do |inbox_id|
      Queue::ProcessQueueJob.perform_later(id, inbox_id)
    end
  end
end
