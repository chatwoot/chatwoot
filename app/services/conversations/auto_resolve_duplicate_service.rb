class Conversations::AutoResolveDuplicateService
  pattr_initialize [:message!]

  def perform
    Rails.logger.info("[AutoResolve] Starting service for message_id=#{message.id}, conversation_id=#{conversation&.id}")

    unless should_auto_resolve?
      Rails.logger.info('[AutoResolve] Skipping - should_auto_resolve returned false')
      return
    end

    duplicates = duplicate_conversations
    Rails.logger.info("[AutoResolve] Found #{duplicates.count} duplicate conversation(s) to resolve")

    duplicates.each do |old_conversation|
      Rails.logger.info("[AutoResolve] Resolving conversation_id=#{old_conversation.id}, display_id=#{old_conversation.display_id}")
      resolve_conversation(old_conversation)
      add_private_note_to_old_conversation(old_conversation)
    end

    Rails.logger.info("[AutoResolve] Completed - resolved #{duplicates.count} conversation(s)")
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def should_auto_resolve? # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    Rails.logger.info('[AutoResolve] Checking conditions:')

    unless inbox.auto_resolve_duplicate_email_conversations?
      Rails.logger.info("[AutoResolve]   ✗ Feature flag disabled for inbox_id=#{inbox.id}")
      return false
    end
    Rails.logger.info('[AutoResolve]   ✓ Feature flag enabled')

    unless inbox.email?
      Rails.logger.info("[AutoResolve]   ✗ Not an email inbox (type: #{inbox.channel_type})")
      return false
    end
    Rails.logger.info('[AutoResolve]   ✓ Email inbox')

    unless message.incoming?
      Rails.logger.info("[AutoResolve]   ✗ Message is not incoming (type: #{message.message_type})")
      return false
    end
    Rails.logger.info('[AutoResolve]   ✓ Incoming message')

    if conversation.nil?
      Rails.logger.info('[AutoResolve]   ✗ Conversation is nil')
      return false
    end
    Rails.logger.info("[AutoResolve]   ✓ Conversation exists (id=#{conversation.id}, display_id=#{conversation.display_id})")

    Rails.logger.info('[AutoResolve]   ✓ All conditions met - proceeding with auto-resolve')
    true
  end

  def duplicate_conversations
    # Find open email conversations from same contact in same inbox
    # Exclude current conversation
    # Order by created_at to resolve older conversations first
    duplicates = inbox.conversations
                      .where(contact_id: contact.id)
                      .where(status: :open)
                      .where.not(id: conversation.id)
                      .order(created_at: :asc)

    Rails.logger.info("[AutoResolve] Query for duplicates: contact_id=#{contact.id}, inbox_id=#{inbox.id}, excluding conversation_id=#{conversation.id}") # rubocop:disable Layout/LineLength
    Rails.logger.info("[AutoResolve] Duplicate conversation IDs: #{duplicates.pluck(:id, :display_id).inspect}")

    duplicates
  end

  def resolve_conversation(old_conversation)
    old_conversation.update!(status: :resolved)
    Rails.logger.info("[AutoResolve] ✓ Resolved conversation_id=#{old_conversation.id}")
  end

  def add_private_note_to_old_conversation(old_conversation)
    content = generate_private_note_content
    params = { content: content, private: true }

    Messages::MessageBuilder.new(nil, old_conversation, params).perform
    Rails.logger.info("[AutoResolve] ✓ Added private note to conversation_id=#{old_conversation.id}")
  end

  def generate_private_note_content
    conversation_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}"
    "This conversation has been automatically resolved. We are now replying on conversation ##{conversation.display_id}: #{conversation_url}"
  end
end
