# Detects a message's language once and keeps it as source_language.
# The conversation language follows the contact's latest message, so a switch midway is picked up.
class Captain::Conversation::MessageLanguageService
  pattr_initialize [:conversation!, :message!]

  def perform
    return message.source_language if message.source_language.present?

    text = Captain::Conversation::MessageText.new(message).texts.join("\n")
    language = Captain::Llm::LanguageDetectionService.new(account: conversation.account, text: text).language
    return if language.blank?

    message.with_lock { message.update!(source_language: language) }
    update_conversation_language(language)
    language
  end

  private

  def update_conversation_language(language)
    return if language == conversation.language || message.auto_reply_email?
    return unless message.incoming? && message.id == conversation.messages.incoming.where.not(content: [nil, '']).maximum(:id)

    conversation.update!(additional_attributes: conversation.additional_attributes.merge('conversation_language' => language))
  end
end
