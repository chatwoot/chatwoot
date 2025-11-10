class Mailbox::ConversationFinderStrategies::ReferencesStrategy < Mailbox::ConversationFinderStrategies::BaseStrategy
  # Patterns from ApplicationMailbox
  MESSAGE_PATTERN = %r{conversation/([a-zA-Z0-9-]+)/messages/(\d+)@}

  # FALLBACK_PATTERN is used when building References headers in ConversationReplyMailer
  # when there's no actual message to reply to (see app/mailers/conversation_reply_mailer.rb#in_reply_to_email).
  # This happens when:
  # - A conversation is started by an agent (no incoming message yet)
  # - The conversation originated from a non-email channel (widget, WhatsApp, etc.) but is now using email
  # - The incoming message doesn't have email metadata with a message_id
  # In these cases, we use a conversation-level identifier instead of a message-level one.
  FALLBACK_PATTERN = %r{account/(\d+)/conversation/([a-zA-Z0-9-]+)@}

  def initialize(mail)
    super(mail)
    # Get channel once upfront to use for scoped queries
    @channel = EmailChannelFinder.new(mail).perform
  end

  def find
    return nil if mail.references.blank?
    return nil unless @channel # No valid channel found

    references = Array.wrap(mail.references)

    references.each do |reference|
      conversation = find_conversation_from_reference(reference)
      return conversation if conversation
    end

    nil
  end

  private

  def find_conversation_from_reference(reference)
    # Try extracting UUID from patterns
    uuid = extract_uuid_from_patterns(reference)
    if uuid
      # Query scoped to inbox - prevents cross-account/cross-inbox matches at database level
      conversation = Conversation.find_by(uuid: uuid, inbox_id: @channel.inbox.id)
      return conversation if conversation
    end

    # We scope to the inbox, that way we filter out messages and conversations that don't belong to the channel
    message = Message.find_by(source_id: reference, inbox_id: @channel.inbox.id)
    message&.conversation
  end

  def extract_uuid_from_patterns(message_id)
    match = MESSAGE_PATTERN.match(message_id)
    return match[1] if match

    match = FALLBACK_PATTERN.match(message_id)
    return match[2] if match

    nil
  end
end
