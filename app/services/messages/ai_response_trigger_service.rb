class Messages::AiResponseTriggerService
  pattr_initialize [:message!]

  def perform
    Rails.logger.info "[AI_TRIGGER] 🎯 STARTING AI TRIGGER CHECK for message #{message.id} (source_id: #{message.source_id}, content: '#{message.content&.truncate(50)}', sender: #{message.sender_type})"

    return false unless should_trigger_ai_response?

    Rails.logger.info "[AI_TRIGGER] 🚀 TRIGGERING AI RESPONSE JOB for message #{message.id} (source_id: #{message.source_id})"
    RequestAiResponseJob.perform_later(message)
    true
  end

  private

  def should_trigger_ai_response?
    Rails.logger.info "[AI_TRIGGER] Checking conditions for message #{message.id}:"

    unless message.persisted?
      Rails.logger.info "[AI_TRIGGER] ❌ Message #{message.id} not persisted"
      return false
    end

    unless message.incoming?
      Rails.logger.info "[AI_TRIGGER] ❌ Message #{message.id} not incoming (message_type: #{message.message_type})"
      return false
    end

    if message.conversation.blank?
      Rails.logger.info "[AI_TRIGGER] ❌ Message #{message.id} has no conversation"
      return false
    end

    if message.conversation.assignee.blank?
      Rails.logger.info "[AI_TRIGGER] ❌ Conversation #{message.conversation.id} has no assignee"
      return false
    end

    unless message.conversation.assignee.is_ai?
      Rails.logger.info "[AI_TRIGGER] ❌ Assignee #{message.conversation.assignee.id} is not AI (is_ai: #{message.conversation.assignee.is_ai?})"
      return false
    end

    if message.conversation.resolved? || message.conversation.snoozed?
      Rails.logger.info "[AI_TRIGGER] ❌ Conversation #{message.conversation.id} is resolved or snoozed (status: #{message.conversation.status})"
      return false
    end

    # Atomic check-and-set to prevent race conditions
    # Use source_id as primary key since duplicate webhook events create different message.id but same source_id
    # Fall back to message.id if source_id is nil (for API channels)
    dedup_key = (message.source_id.presence || "msg_#{message.id}")
    redis_key = "ai_response_triggered:#{dedup_key}"
    Rails.logger.info "[AI_TRIGGER] Attempting atomic lock for Redis key: #{redis_key} (source_id: #{message.source_id}, msg_id: #{message.id})"

    # Use atomic SET with NX (only set if not exists) and EX (expiry)
    timestamp = Time.current.iso8601
    lock_acquired = Redis::Alfred.set(redis_key, timestamp, nx: true, ex: 3600)

    unless lock_acquired
      Rails.logger.info "[AI_TRIGGER] ❌ AI response already triggered for source_id #{message.source_id} (message #{message.id}), skipping (atomic lock failed)"
      return false
    end

    Rails.logger.info "[AI_TRIGGER] ✅ Acquired atomic lock for source_id #{message.source_id} (message #{message.id}) with key: #{redis_key}"

    Rails.logger.info "[AI_TRIGGER] ✅ All conditions met for message #{message.id}: " \
                      "assignee=#{message.conversation.assignee.id}, " \
                      "is_ai=#{message.conversation.assignee.is_ai?}, " \
                      "status=#{message.conversation.status}"

    true
  end
end
