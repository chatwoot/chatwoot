class Captain::Conversation::AutoTranslateService
  BATCH_LIMIT = 20
  MAX_CONTENT_LENGTH = 20_000
  BOT_SENDERS = %w[AgentBot Captain::Assistant].freeze

  pattr_initialize [:conversation!, :message_ids!, :target_language!]

  def perform
    already_in_target, pending = untranslated.partition { |message| same_language?(message.content_attributes['source_language'], target_language) }
    already_in_target.each { |message| store(message, text(message).original) }
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
                              .merge(Message.incoming.or(Message.where(sender_type: BOT_SENDERS)))
  end

  def untranslated
    @untranslated ||= messages.reject { |message| settled?(message) }
  end

  def settled?(message)
    message.translations&.key?(target_language) || text(message).texts.sum(&:length) > MAX_CONTENT_LENGTH
  end

  def text(message)
    @text ||= {}
    @text[message.id] ||= Captain::Conversation::MessageText.new(message)
  end

  # Every text of a message is a segment of its own, so html emails come back with their markup untouched.
  def translate(pending)
    segments = pending.flat_map { |message| text(message).texts.map { |content| [message, content] } }
    translations = translations_for(segments.map(&:last))
    raise StandardError, I18n.t('captain.translation_incomplete') if translations.size != segments.size

    by_message = Hash.new { |hash, key| hash[key] = [] }
    segments.zip(translations) { |(message, _), translated| by_message[message.id] << translated }
    pending.each { |message| store(message, text(message).translated(by_message[message.id])) }
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

    language = text(untranslated.last).language
    conversation.update!(additional_attributes: conversation.additional_attributes.merge(conversation_language: language)) if language
  end

  def same_language?(first, second)
    Captain::Llm::MessageTranslationService.same_language?(first, second)
  end
end
