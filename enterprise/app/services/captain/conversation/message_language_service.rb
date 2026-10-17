class Captain::Conversation::MessageLanguageService
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
    return unless message.id == conversation.messages.incoming.where(content_type: %w[text incoming_email]).where.not(content: [nil, '']).maximum(:id)

    conversation.update!(additional_attributes: conversation.additional_attributes.merge('conversation_language' => language))
  end
end
