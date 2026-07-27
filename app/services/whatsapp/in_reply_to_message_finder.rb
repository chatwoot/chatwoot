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
    matches = conversation.messages.where('source_id LIKE ?', 'wamid.%').select(:id, :source_id).select do |message|
      message_token(message.source_id) == token
    end.uniq(&:source_id)

    matches.one? ? matches.first : nil
  end

  def message_token(message_id)
    return unless message_id.start_with?('wamid.')

    tokens = Base64.strict_decode64(message_id.delete_prefix('wamid.')).scan(RegexHelper::WHATSAPP_WAMID_TOKEN_REGEX)
    tokens.one? ? tokens.first.downcase : nil
  rescue ArgumentError
    nil
  end
end
