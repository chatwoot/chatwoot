class Captain::Conversation::MessageLanguageService
  # The conversation follows the language most of the contact's recent messages are in, so one short message
  # such as a city name or a typo cannot switch the replies on its own.
  VOTING_MESSAGES = 5

  pattr_initialize [:conversation!, :message!]

  def perform
    return message.source_language if message.source_language.present?

    language = Captain::Conversation::TranslatorService.new(account: conversation.account).language(message.content)
    return if language.blank?

    message.with_lock { message.update!(source_language: language) }
    update_conversation_language(language)
    language
  end

  private

  def update_conversation_language(language)
    return if language == conversation.language || message.auto_reply_email?
    return unless message.id == contact_text_messages.maximum(:id)

    majority = majority_language
    return if majority == conversation.language

    Rails.logger.info("[AutoTranslate] conversation #{conversation.id} language #{conversation.language.inspect} -> #{majority}")
    conversation.update!(additional_attributes: conversation.additional_attributes.merge('conversation_language' => majority))
  end

  # Messages without a detected language are skipped. Newest first, so a tie goes to the most recent language.
  def majority_language
    languages = contact_text_messages.reorder(id: :desc).limit(VOTING_MESSAGES).filter_map(&:source_language)
    counts = languages.tally
    languages.find { |language| counts[language] == counts.values.max }
  end

  def contact_text_messages
    conversation.messages.incoming.where(content_type: %w[text incoming_email]).where.not(content: [nil, ''])
  end
end
