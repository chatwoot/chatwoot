class Whatsapp::InReplyToMessageFinder
  pattr_initialize [:conversation!, :source_id!]

  def perform
    exact_match || matching_scoped_message
  end

  private

  def exact_match
    conversation.messages.find_by(source_id: source_id)
  end

  def matching_scoped_message
    token = message_token(source_id)
    return if token.blank?

    # Phone-scoped and BSUID-scoped WAMIDs can carry the same message token
    # even when their complete source IDs differ.
    matching_message = nil
    ambiguous_match = false

    conversation.messages.where('source_id LIKE ?', 'wamid.%').select(:id, :source_id).find_each do |message|
      next unless message_token(message.source_id) == token
      next if matching_message&.source_id == message.source_id

      if matching_message
        ambiguous_match = true
        break
      end

      matching_message = message
    end

    matching_message unless ambiguous_match
  end

  def message_token(message_id)
    return unless message_id.start_with?('wamid.')

    tokens = Base64.strict_decode64(message_id.delete_prefix('wamid.')).scan(RegexHelper::WHATSAPP_WAMID_TOKEN_REGEX)
    tokens.one? ? tokens.first.downcase : nil
  rescue ArgumentError
    nil
  end
end
