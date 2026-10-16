class Captain::Conversation::AutoTranslateService
  BATCH_LIMIT = 20
  MAX_CONTENT_LENGTH = 20_000
  BOT_SENDERS = %w[AgentBot Captain::Assistant].freeze

  pattr_initialize [:conversation!, :message_ids!, :target_language!]

  def perform
    already_in_target, pending = untranslated.partition { |message| same_language?(message.content_attributes['source_language'], target_language) }
    already_in_target.each { |message| store(message, message.content) }
    translate(pending) if pending.any?
    # Reloaded: a message that arrived during the model call may have set the language already.
    detect_conversation_language if conversation.reload.language.blank?

    # Everything the server settled: translated, or too long to ever be.
    messages.select { |message| settled?(message) }
  end

  private

  # Contact messages and bot replies both read in the contact language.
  def messages
    @messages ||= conversation.messages.where(id: message_ids.first(BATCH_LIMIT)).where.not(content: [nil, '']).order(:id)
                              .merge(Message.incoming.or(Message.where(sender_type: BOT_SENDERS))).reject(&:html_email?)
  end

  def untranslated
    @untranslated ||= messages.reject { |message| settled?(message) }
  end

  def settled?(message)
    message.translations&.key?(target_language) || message.content.length > MAX_CONTENT_LENGTH
  end

  def translate(pending)
    translations = translations_for(pending.map(&:content))
    raise StandardError, I18n.t('captain.translation_incomplete') if translations.size != pending.size

    pending.each_with_index { |message, index| store(message, translations[index]) }
  end

  def translations_for(texts)
    response = Captain::Llm::MessageTranslationService.new(
      account: conversation.account, texts: texts, target_language: target_language, conversation_display_id: conversation.display_id
    ).perform
    raise StandardError, response[:error] if response[:error]

    response[:message]
  end

  # Merged under the row lock: the model call takes seconds, and another agent's translation or a deletion
  # may have landed on the message meanwhile.
  def store(message, content)
    message.with_lock do
      translations = (message.translations || {}).merge(target_language => content)
      message.update!(content_attributes: message.content_attributes.merge('translations' => translations))
    end
  end

  # Messages from before the feature carry no language; the thread follows its latest one.
  def detect_conversation_language
    return if untranslated.empty?

    language = Captain::Llm::LanguageDetectionService.new(account: conversation.account, text: untranslated.last.content).language
    conversation.update!(additional_attributes: conversation.additional_attributes.merge(conversation_language: language)) if language
  end

  def same_language?(first, second)
    Captain::Llm::MessageTranslationService.same_language?(first, second)
  end
end
