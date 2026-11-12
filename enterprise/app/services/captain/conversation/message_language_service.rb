class Captain::Conversation::MessageLanguageService
  # Detection is unreliable on a word or two, such as a city name or a typo. So the conversation follows the contact's
  # newest message that has a few words, or that is in the same language as the message before it.
  RECENT_MESSAGES = 5
  MIN_WORDS = 3
  # Scripts written without spaces between words count each character as a word. Elsewhere a word needs a letter,
  # so numbers, emoji and punctuation do not make a short message look long.
  NO_SPACE_CHARACTER = /[\p{Han}\p{Hiragana}\p{Katakana}\p{Thai}\p{Lao}\p{Khmer}\p{Myanmar}]/

  pattr_initialize [:conversation!, :message!, { translator: nil }]

  def perform
    return message.source_language if message.source_language.present?

    language = translator.language(message.content)
    return if language.blank?

    message.with_lock { message.update!(source_language: language) }
    update_conversation_language(language)
    language
  end

  private

  def translator
    @translator ||= Captain::Conversation::TranslatorService.new(account: conversation.account)
  end

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

  # Returns nil, which keeps the current language, when no recent message is reliable.
  def recent_language(detected)
    detected.each_with_index do |recent_message, index|
      language = recent_message.source_language
      return language if word_count(recent_message.content) >= MIN_WORDS || language == detected[index + 1]&.source_language
    end
    detected.first.source_language if conversation.language.blank?
  end

  def word_count(text)
    no_space_characters = text.scan(NO_SPACE_CHARACTER).size
    words = text.gsub(NO_SPACE_CHARACTER, ' ').split.count { |word| word.match?(/\p{L}/) }
    no_space_characters + words
  end

  # Email auto replies are left out, so out-of-office messages cannot pick the reply language.
  def recent_detected_messages
    conversation.messages.captain_response_triggering.where(content_type: %w[text incoming_email]).where.not(content: [nil, ''])
                .reorder(id: :desc).limit(RECENT_MESSAGES).select { |recent_message| recent_message.source_language.present? }
  end
end
