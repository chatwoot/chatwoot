class Captain::Conversation::MessageLanguageService
  # Detection is unreliable on a word or two, such as a city name or a typo. So the conversation follows the contact's
  # newest message that has a few words, or that is in the same language as the message before it.
  RECENT_MESSAGES = 5
  MIN_WORDS = 3
  # Scripts written without spaces between words count each character as a word. Elsewhere a word needs a letter,
  # so numbers, emoji and punctuation do not make a short message look long.
  NO_SPACE_SCRIPTS = '\p{Han}\p{Hiragana}\p{Katakana}\p{Thai}\p{Lao}\p{Khmer}\p{Myanmar}'.freeze
  WORD = /[#{NO_SPACE_SCRIPTS}]|[^\s#{NO_SPACE_SCRIPTS}]*\p{L}[^\s#{NO_SPACE_SCRIPTS}]*/

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

  # Any recent message can change the result, because the dashboard detects messages in parallel and the newest
  # one may finish before the older ones.
  def update_conversation_language(language)
    return if language == conversation.language

    detected = recent_detected_messages
    return unless detected.include?(message)

    new_language = recent_language(detected)
    return if new_language.nil? || new_language == conversation.language

    Rails.logger.info("[AutoTranslate] conversation #{conversation.id} language #{conversation.language.inspect} -> #{new_language}")
    conversation.update!(additional_attributes: conversation.additional_attributes.merge('conversation_language' => new_language))
  end

  # Newest first. When no recent message is reliable, the current language stays, or the newest message
  # sets it when the conversation has none yet.
  def recent_language(detected)
    detected.each_with_index do |recent_message, index|
      language = recent_message.source_language
      return language if recent_message.content.scan(WORD).size >= MIN_WORDS || language == detected[index + 1]&.source_language
    end
    detected.first.source_language if conversation.language.blank?
  end

  # Email auto replies are left out, so out-of-office messages cannot pick the reply language.
  def recent_detected_messages
    conversation.messages.captain_response_triggering.where(content_type: %w[text incoming_email]).where.not(content: [nil, ''])
                .reorder(id: :desc).limit(RECENT_MESSAGES).select { |recent_message| recent_message.source_language.present? }
  end
end
