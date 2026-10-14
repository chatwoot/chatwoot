class Captain::Conversation::AutoTranslateService
  BATCH_LIMIT = 20
  MAX_CONTENT_LENGTH = 20_000

  pattr_initialize [:conversation!, :message_ids!, :target_language!]

  def perform
    already_in_target, pending = untranslated.partition { |message| same_language?(text(message).language, target_language) }
    already_in_target.each { |message| store(message, text(message).original) }
    translate(pending) if pending.any?
    detect_conversation_language if conversation.language.blank?

    messages.select { |message| message.translations&.key?(target_language) }
  end

  private

  def messages
    @messages ||= conversation.messages.incoming.where(id: message_ids.first(BATCH_LIMIT)).where.not(content: [nil, '']).order(:id)
  end

  def untranslated
    @untranslated ||= messages.reject do |message|
      message.translations&.key?(target_language) || text(message).texts.sum(&:length) > MAX_CONTENT_LENGTH
    end
  end

  def text(message)
    @text ||= {}
    @text[message.id] ||= Captain::Conversation::MessageText.new(message)
  end

  def translate(pending)
    response = Captain::Llm::MessageTranslationService.new(
      account: conversation.account,
      texts: segments(pending),
      target_language: target_language,
      conversation_display_id: conversation.display_id
    ).perform
    raise StandardError, response[:error] if response[:error]

    translations = translations_by_message(response[:message])
    pending.each { |message| store(message, text(message).translated(translations[message.id])) if translations.key?(message.id) }
  end

  # Every text of a message is a segment of its own, so html emails come back with their markup untouched.
  def segments(pending)
    pending.flat_map do |message|
      text(message).texts.each_with_index.map { |content, index| { id: "#{message.id}:#{index}", content: content } }
    end
  end

  def translations_by_message(items)
    items.each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |item, grouped|
      message_id, index = item['id'].to_s.split(':').map(&:to_i)
      grouped[message_id][index] = item['text']
    end
  end

  # Merged under the row lock: the model call takes seconds, and another agent's translation or a deletion
  # may have landed on the message meanwhile. The source language keeps "Translated from" right after a thread switch.
  def store(message, content)
    message.with_lock do
      attributes = message.content_attributes.merge(
        'translations' => (message.translations || {}).merge(target_language => content),
        'source_language' => text(message).language
      )
      message.update!(content_attributes: attributes.compact)
    end
  end

  def detect_conversation_language
    untranslated.each { |message| Captain::Conversation::DetectLanguageService.new(message: message).perform }
  end

  def same_language?(first, second)
    Captain::Llm::MessageTranslationService.same_language?(first, second)
  end
end
