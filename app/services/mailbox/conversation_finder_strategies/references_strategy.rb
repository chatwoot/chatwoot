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

  def find
    return nil if mail.references.blank?

    references = Array.wrap(mail.references)

    references.each do |reference|
      conversation = find_conversation_from_reference(reference)
      next unless conversation && conversation_belongs_to_channel?(conversation)

      return conversation
    end

    nil
  end

  private

  def find_conversation_from_reference(reference)
    # Try extracting UUID from patterns
    uuid = extract_uuid_from_patterns(reference)
    if uuid
      conversation = Conversation.find_by(uuid: uuid)
      return conversation if conversation
    end

    # Try finding by message source_id
    message = Message.find_by(source_id: reference)
    message&.conversation
  end

  def extract_uuid_from_patterns(message_id)
    # Try message-specific pattern first
    match = MESSAGE_PATTERN.match(message_id)
    return match[1] if match

    # Try conversation fallback pattern
    match = FALLBACK_PATTERN.match(message_id)
    return match[2] if match

    nil
  end

  def conversation_belongs_to_channel?(conversation)
    # Get the channel from the email's To/CC addresses
    channel = EmailChannelFinder.new(mail).perform
    return false unless channel

    # Check if the conversation's inbox matches the channel
    conversation.inbox.channel_id == channel.id
  end
end
