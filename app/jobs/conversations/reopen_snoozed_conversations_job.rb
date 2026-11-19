class Conversations::ReopenSnoozedConversationsJob < ApplicationJob
  queue_as :low

  MAX_PROCESS_LIMIT = 500
  LOCK_TIMEOUT = 10.minutes
  MAX_EXECUTION_TIME = 8.minutes

  def perform(limit = MAX_PROCESS_LIMIT)
    lock_manager = Redis::LockManager.new
    return unless lock_manager.lock(Redis::Alfred::REOPEN_SNOOZED_CONVERSATIONS_MUTEX, LOCK_TIMEOUT)

    start_time = Time.current
    should_re_enqueue = false

    begin
      batch = snoozed_conversations.order(:snoozed_until).limit(limit).to_a
      timed_out = false

      batch.each do |conversation|
        if Time.current - start_time >= MAX_EXECUTION_TIME
          timed_out = true
          break
        end

        conversation.with_lock do
          conversation.reload
          next unless conversation.snoozed? && conversation.snoozed_until.present? && conversation.snoozed_until <= Time.current

          conversation.open!
        end
      end

      should_re_enqueue = (batch.size >= limit || timed_out) && snoozed_conversations.exists?
    ensure
      lock_manager.unlock(Redis::Alfred::REOPEN_SNOOZED_CONVERSATIONS_MUTEX) if Time.current - start_time < LOCK_TIMEOUT
    end

    self.class.perform_later(limit) if should_re_enqueue
  end

  private

  def snoozed_conversations
    Conversation.where(status: :snoozed).where(snoozed_until: ..Time.current)
  end
end
