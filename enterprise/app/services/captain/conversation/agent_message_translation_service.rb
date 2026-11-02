class Captain::Conversation::AgentMessageTranslationService
  include EmailHelper

  TRANSLATABLE_CTA_FIELDS = %w[body display_text header footer].freeze
  CTA_FIELD_MAX_LENGTHS = {
    'display_text' => ContentAttributeValidator::WHATSAPP_CTA_DISPLAY_TEXT_MAX_LENGTH,
    'header' => ContentAttributeValidator::WHATSAPP_CTA_HEADER_FOOTER_MAX_LENGTH,
    'footer' => ContentAttributeValidator::WHATSAPP_CTA_HEADER_FOOTER_MAX_LENGTH
  }.freeze

  pattr_initialize [:message!]

  def perform
    detect_contact_language
    translate_reply if conversation.language.present?

    message.content_attributes.delete('translation_pending')
    message.save!
  end

  private

  delegate :conversation, :account, :inbox, to: :message

  def detect_contact_language
    contact_message = conversation.messages.incoming.where(content_type: %w[text incoming_email]).where.not(content: [nil, '']).order(:id).last
    Captain::Conversation::MessageLanguageService.new(conversation: conversation, message: contact_message).perform if contact_message
  end

  def translate_reply
    reply_result = evaluate_segment(reply)
    cta_results = evaluate_whatsapp_cta_segments
    apply_translation(reply_result, cta_results)
  end

  def apply_translation(reply_result, cta_results)
    all_results = [reply_result, *cta_results.values]
    if translation_failed_or_over_limit?(reply_result, cta_results, all_results)
      message.translation_failed = true
    elsif all_results.any? { |res| res[:status] == :translated }
      use_translation(reply_result, cta_results)
    end
  end

  def translation_failed_or_over_limit?(reply_result, cta_results, all_results)
    return true if all_results.any? { |res| res[:status] == :failed }
    return false unless all_results.any? { |res| res[:status] == :translated }

    over_whatsapp_cta_limit?(reply_result, cta_results)
  end

  def evaluate_segment(text)
    return { status: :unchanged, text: text, lang: nil } if text.blank?

    lang = detected_language_for(text)
    return { status: :unchanged, text: text, lang: lang } if same_conversation_language?(lang)

    candidate = translated_text_for(text)
    status = segment_status(text, candidate, lang)
    { status: status, text: status == :translated ? candidate : text, lang: lang }
  end

  def segment_status(source, candidate, lang)
    return :failed if candidate.blank?
    return :translated if candidate != source

    lang.present? ? :failed : :unchanged
  end

  def evaluate_whatsapp_cta_segments
    return {} unless whatsapp_cta_reply?

    TRANSLATABLE_CTA_FIELDS.each_with_object({}) do |field, results|
      value = whatsapp_cta_field(field)
      results[field] = evaluate_segment(value) if value.present?
    end
  end

  def use_translation(reply_result, cta_results)
    apply_reply_translation(reply_result) if reply_result[:status] == :translated
    update_whatsapp_cta_fields(cta_results) if cta_results.present?
  end

  def apply_reply_translation(reply_result)
    message.translations = { original_language(reply_result[:lang]) => original_text }
    message.source_language = conversation.language
    message.translation_provider = translator.provider
    message.content = with_quoted_history(reply_result[:text])
    message.content_attributes['email'] = email_content(message.content) if email_reply?
  end

  def same_conversation_language?(lang)
    Captain::Llm::MessageTranslationService.same_language?(lang, conversation.language)
  end

  def whatsapp_cta_params
    params = message.content_attributes['whatsapp_cta_url'] || message.content_attributes[:whatsapp_cta_url]
    params if params.is_a?(Hash)
  end

  def whatsapp_cta_reply?
    whatsapp_cta_params.present?
  end

  def whatsapp_cta_field(field)
    params = whatsapp_cta_params
    value = params && (params[field] || params[field.to_sym])
    value if value.is_a?(String) && value.present?
  end

  def over_whatsapp_cta_limit?(reply_result, cta_results)
    return false unless whatsapp_cta_reply?
    return true if over_cta_metadata_limits?(cta_results)

    effective_cta_body(reply_result, cta_results).length > ContentAttributeValidator::WHATSAPP_CTA_BODY_MAX_LENGTH
  end

  def over_cta_metadata_limits?(cta_results)
    CTA_FIELD_MAX_LENGTHS.any? do |field, max_len|
      text = cta_results.dig(field, :text) || whatsapp_cta_field(field)
      text.present? && text.length > max_len
    end
  end

  def effective_cta_body(reply_result, cta_results)
    explicit_body = cta_results.dig('body', :text) || whatsapp_cta_field('body')
    return explicit_body if explicit_body.present?

    next_content = reply_result[:status] == :translated ? with_quoted_history(reply_result[:text]) : message.content
    ContentAttributeValidator.rendered_whatsapp_body(next_content.to_s, inbox.channel)
  end

  def update_whatsapp_cta_fields(cta_results)
    translated_fields = cta_results.each_with_object({}) do |(field, res), acc|
      acc[field] = res[:text] if res[:status] == :translated
    end
    return if translated_fields.empty?

    cta_key = message.content_attributes.key?(:whatsapp_cta_url) ? :whatsapp_cta_url : 'whatsapp_cta_url'
    keys_to_replace = translated_fields.keys.flat_map { |k| [k, k.to_sym] }
    message.content_attributes[cta_key] = whatsapp_cta_params.except(*keys_to_replace).merge(translated_fields)
  end

  def detected_language_for(text)
    @detected_languages ||= {}
    return @detected_languages[text] if @detected_languages.key?(text)

    @detected_languages[text] = detect(text)
  end

  def translated_text_for(text)
    @translated_texts ||= {}
    return @translated_texts[text] if @translated_texts.key?(text)

    @translated_texts[text] = translator.translate(text, conversation.language)
  end

  def original_language(detected_lang)
    detected_lang || agent_locale || account.locale
  end

  def detect(text)
    translator.language(text)
  end

  def translator
    @translator ||= Captain::Conversation::TranslatorService.new(account: account, conversation_display_id: conversation.display_id)
  end

  def agent_locale
    message.sender.ui_settings['locale'].presence if message.sender.is_a?(User)
  end

  # Email: the reply box appends the earlier thread as "> " lines. Only the text above them is translated.

  def reply
    @reply ||= quoted_history.blank? ? message.content : message.content.delete_suffix(quoted_history).strip
  end

  def quoted_history
    @quoted_history ||= inbox.email? ? message.content[/^>.*\z/m].to_s : ''
  end

  def with_quoted_history(translated)
    quoted_history.blank? ? translated : "#{translated.strip}\n\n#{quoted_history}"
  end

  # Kept as html like the sent mail, so the quoted thread stays collapsed in the dashboard.
  def original_text
    email_reply? ? String.new(render_email_html(normalize_email_body(message.content))) : message.content
  end

  # Only replies built by the message builder carry the email; templates like greeting and CSAT are mailed from their content.
  def email_reply?
    inbox.email? && message.content_attributes['email'].present?
  end

  # The mailer sends the stored html, so it is rendered again from the translated text.
  # The renderer returns a SafeBuffer, which Sidekiq rejects in the message updated broadcast, so it is stored as a String.
  def email_content(content)
    text = normalize_email_body(content)
    html = String.new(render_email_html(text))
    message.content_attributes['email']
           .merge('html_content' => { 'full' => html, 'reply' => html }, 'text_content' => { 'full' => text, 'reply' => text })
  end
end
