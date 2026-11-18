class Conversations::ReopenSnoozedConversationsJob < ApplicationJob
  queue_as :low

  MAX_PROCESS_LIMIT = 500
  LOCK_TIMEOUT = 10.minutes

  def perform(limit = MAX_PROCESS_LIMIT)
    lock_manager = Redis::LockManager.new
    return unless lock_manager.lock(Redis::Alfred::REOPEN_SNOOZED_CONVERSATIONS_MUTEX, LOCK_TIMEOUT)

    should_re_enqueue = false

    begin
      reopened_count = 0

      snoozed_conversations.order(:snoozed_until).limit(limit).each do |conversation|
        conversation.with_lock do
          conversation.reload
          next unless conversation.snoozed? && conversation.snoozed_until.present? && conversation.snoozed_until <= Time.current

          conversation.open!
          reopened_count += 1
        end
      end

      should_re_enqueue = reopened_count >= limit && snoozed_conversations.exists?
    ensure
      lock_manager.unlock(Redis::Alfred::REOPEN_SNOOZED_CONVERSATIONS_MUTEX)
    end

    self.class.perform_later(limit) if should_re_enqueue
  end

  private

  def snoozed_conversations
    Conversation.where(status: :snoozed).where(snoozed_until: ..Time.current)
  end
end
