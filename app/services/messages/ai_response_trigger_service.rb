class Messages::AiResponseTriggerService
  include Events::Types

  pattr_initialize [:message!]

  def perform
    Rails.logger.info "[AI_TRIGGER] 🎯 STARTING AI TRIGGER CHECK for message #{message.id} (source_id: #{message.source_id}, content: '#{message.content&.truncate(50)}', sender: #{message.sender_type})"

    return false unless should_trigger_ai_response?

    # Show typing indicator for AI agent
    show_ai_typing_indicator

    Rails.logger.info "[AI_TRIGGER] 🚀 TRIGGERING AI RESPONSE JOB for message #{message.id} (source_id: #{message.source_id})"
    RequestAiResponseJob.perform_later(message)
    true
  end

  private

  def should_trigger_ai_response?
    Rails.logger.info "[AI_TRIGGER] Checking conditions for message #{message.id}:"

    unless message.persisted?
      Rails.logger.info "[AI_TRIGGER] Message #{message.id} not persisted"
      return false
    end

    unless message.incoming?
      Rails.logger.info "[AI_TRIGGER] Message #{message.id} not incoming (message_type: #{message.message_type})"
      return false
    end

    if message.conversation.blank?
      Rails.logger.info "[AI_TRIGGER] Message #{message.id} has no conversation"
      return false
    end

    if message.conversation.assignee.blank?
      Rails.logger.info "[AI_TRIGGER] Conversation #{message.conversation.id} has no assignee"
      return false
    end

    unless message.conversation.assignee.is_ai?
      Rails.logger.info "[AI_TRIGGER] Assignee #{message.conversation.assignee.id} is not AI (is_ai: #{message.conversation.assignee.is_ai?})"
      return false
    end

    if message.conversation.resolved? || message.conversation.snoozed?
      Rails.logger.info "[AI_TRIGGER] Conversation #{message.conversation.id} is resolved or snoozed (status: #{message.conversation.status})"
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
      Rails.logger.info "[AI_TRIGGER] AI response already triggered for source_id #{message.source_id} (message #{message.id}), skipping (atomic lock failed)"
      return false
    end

    Rails.logger.info "[AI_TRIGGER] ✅ Acquired atomic lock for source_id #{message.source_id} (message #{message.id}) with key: #{redis_key}"

    Rails.logger.info "[AI_TRIGGER] ✅ All conditions met for message #{message.id}: " \
                      "assignee=#{message.conversation.assignee.id}, " \
                      "is_ai=#{message.conversation.assignee.is_ai?}, " \
                      "status=#{message.conversation.status}"

    true
  end

  def show_ai_typing_indicator
    conversation = message.conversation
    ai_agent = conversation.assignee

    return unless ai_agent&.is_ai?

    Rails.logger.info "[AI_TRIGGER] 💬 Showing typing indicator for AI agent #{ai_agent.id} in conversation #{conversation.id}"

    # Trigger typing_on event for the AI agent (UI/WebSocket)
    Rails.configuration.dispatcher.dispatch(
      CONVERSATION_TYPING_ON,
      Time.zone.now,
      conversation: conversation,
      user: ai_agent,
      is_private: false
    )

    # Send typing indicator to WhatsApp if applicable
    send_whatsapp_typing_indicator(conversation)
  rescue StandardError => e
    Rails.logger.error "[AI_TRIGGER] Failed to show typing indicator: #{e.message}"
  end

  # Send typing indicator to WhatsApp if the conversation is on WhatsApp channel
  # Marks the incoming message as read and shows typing indicator
  def send_whatsapp_typing_indicator(conversation)
    inbox = conversation.inbox
    return unless inbox.channel_type == 'Channel::Whatsapp'

    channel = inbox.channel
    return unless channel.respond_to?(:provider_name) && channel.provider_name == 'whatsapp_cloud'

    phone_number = conversation.contact_inbox.source_id
    return if phone_number.blank?

    # Get WhatsApp message ID from the incoming message's source_id
    whatsapp_message_id = message.source_id
    return if whatsapp_message_id.blank?

    Rails.logger.info "[AI_TRIGGER] 📱 Sending WhatsApp typing indicator to #{phone_number} for message #{whatsapp_message_id}"

    # Use the WhatsApp Cloud Service to send typing indicator and mark message as read
    service = Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel)
    service.send_typing_indicator(phone_number, message_id: whatsapp_message_id)
  rescue StandardError => e
    Rails.logger.error "[AI_TRIGGER] Failed to send WhatsApp typing indicator: #{e.message}"
  end
end
