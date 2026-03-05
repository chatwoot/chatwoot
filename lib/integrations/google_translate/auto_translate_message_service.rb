class Integrations::GoogleTranslate::AutoTranslateMessageService
  pattr_initialize [:hook!, :message!]

  def perform
    return unless valid_message?

    target_language = normalize_language(target_language_for_message)
    return if target_language.blank?
    return if same_as_source_language?(target_language)
    return if translated_content_for(target_language).present?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: target_language
    ).perform

    return if translated_content.blank?

    message.update!(translations: merged_translations(target_language, translated_content))
  end

  private

  def valid_message?
    message.present? &&
      message.content.present? &&
      !message.private? &&
      (message.incoming? || message.outgoing?)
  end

  def target_language_for_message
    return message.account.locale if message.incoming? && auto_translate_incoming?
    return conversation_language if message.outgoing? && auto_translate_outgoing?

    nil
  end

  def auto_translate_incoming?
    return true if hook.settings['auto_translate_incoming'].nil?

    hook.settings['auto_translate_incoming']
  end

  def auto_translate_outgoing?
    hook.settings['auto_translate_outgoing'] == true
  end

  def conversation_language
    message.conversation.additional_attributes['conversation_language']
  end

  def same_as_source_language?(target_language)
    source_language = message.incoming? ? conversation_language : message.account.locale
    normalize_language(source_language) == target_language
  end

  def translated_content_for(target_language)
    message.translations&.[](target_language)
  end

  def merged_translations(target_language, translated_content)
    (message.translations || {}).merge(target_language => translated_content)
  end

  def normalize_language(language)
    language.to_s.tr('-', '_').presence
  end
end
