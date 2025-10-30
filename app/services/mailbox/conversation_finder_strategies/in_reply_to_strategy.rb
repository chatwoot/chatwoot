class Mailbox::ConversationFinderStrategies::InReplyToStrategy < Mailbox::ConversationFinderStrategies::BaseStrategy
  # Patterns from ApplicationMailbox
  MESSAGE_PATTERN = %r{conversation/([a-zA-Z0-9-]+)/messages/(\d+)@}
  FALLBACK_PATTERN = %r{account/(\d+)/conversation/([a-zA-Z0-9-]+)@}

  def find
    return nil if mail.in_reply_to.blank?

    in_reply_to_addresses = Array.wrap(mail.in_reply_to)

    in_reply_to_addresses.each do |in_reply_to|
      # Try extracting UUID from patterns
      uuid = extract_uuid_from_patterns(in_reply_to)
      if uuid
        conversation = Conversation.find_by(uuid: uuid)
        return conversation if conversation
      end

      # Try finding by message source_id
      message = Message.find_by(source_id: in_reply_to)
      return message.conversation if message&.conversation
    end

    nil
  end

  private

  def extract_uuid_from_patterns(message_id)
    # Try message-specific pattern first
    match = MESSAGE_PATTERN.match(message_id)
    return match[1] if match

    # Try conversation fallback pattern
    match = FALLBACK_PATTERN.match(message_id)
    return match[2] if match

    nil
  end
end
