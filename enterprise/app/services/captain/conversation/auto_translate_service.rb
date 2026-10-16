class Captain::Conversation::AutoTranslateService
  BATCH_LIMIT = 20
  BOT_SENDERS = %w[AgentBot Captain::Assistant].freeze

  pattr_initialize [:conversation!, :message_ids!, :target_language!]

  def perform
    own_language, foreign = untranslated.partition { |message| written_in_target?(message) }
    own_language.each { |message| store(message, message.content) }
    translate(foreign) if foreign.any?
    detect_conversation_language if conversation.language.blank?
    messages
  end

  private

  # Contact messages and bot replies both read in the contact language.
  def messages
    @messages ||= conversation.messages.where(id: message_ids.first(BATCH_LIMIT)).where.not(content: [nil, '']).order(:id)
                              .merge(Message.incoming.or(Message.where(sender_type: BOT_SENDERS))).reject(&:html_email?)
  end

  def untranslated
    @untranslated ||= messages.reject { |message| message.translations&.key?(target_language) }
  end

  def written_in_target?(message)
    Captain::Llm::MessageTranslationService.same_language?(message.content_attributes['source_language'], target_language)
  end

  def translate(pending)
    response = Captain::Llm::MessageTranslationService.new(
      account: conversation.account, texts: pending.map(&:content), target_language: target_language, conversation_display_id: conversation.display_id
    ).perform
    raise StandardError, response[:error] if response[:error]
    raise StandardError, I18n.t('captain.translation_incomplete') if response[:message].size != pending.size

    pending.each_with_index { |message, index| store(message, response[:message][index]) }
  end

  # Under the row lock: another agent's translation or a deletion may have landed during the model call.
  def store(message, text)
    message.with_lock do
      message.update!(content_attributes: message.content_attributes.deep_merge('translations' => { target_language => text }))
    end
  end

  # Messages from before the feature carry no language; the thread follows its latest one.
  def detect_conversation_language
    return if untranslated.empty?

    language = Captain::Llm::LanguageDetectionService.new(account: conversation.account, text: untranslated.last.content).language
    conversation.update!(additional_attributes: conversation.additional_attributes.merge(conversation_language: language)) if language
  end
end
