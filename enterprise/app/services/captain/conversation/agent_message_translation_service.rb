class Captain::Conversation::AgentMessageTranslationService
  include EmailHelper

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
    need_reply = !same_conversation_language?(reply_language)
    need_cta = distinct_cta_body? && !same_conversation_language?(cta_body_language)
    return unless need_reply || need_cta

    translated = need_reply ? translate : reply
    translated_cta = translated_cta_body_for(translated, need_cta)
    apply_translation(translated, translated_cta, need_reply, need_cta)
  end

  def apply_translation(translated, translated_cta, need_reply, need_cta)
    if over_whatsapp_cta_limit?(translated, translated_cta)
      message.translation_failed = true
    elsif usable_translation?(translated, translated_cta, need_reply, need_cta)
      use_translation(translated, translated_cta, need_reply)
    elsif translation_error?(translated, translated_cta, need_reply, need_cta)
      message.translation_failed = true
    end
  end

  def usable_translation?(translated, translated_cta, need_reply, need_cta)
    reply_ready = !need_reply || valid_segment_translation?(translated, reply)
    cta_ready = !need_cta || valid_segment_translation?(translated_cta, whatsapp_cta_body)
    reply_ready && cta_ready
  end

  def valid_segment_translation?(candidate, source)
    candidate.present? && candidate != source
  end

  def translation_error?(translated, translated_cta, need_reply, need_cta)
    segment_failed?(need_reply, translated, reply_language) || segment_failed?(need_cta, translated_cta, cta_body_language)
  end

  def segment_failed?(needed, candidate, detected_lang)
    needed && (candidate.blank? || detected_lang.present?)
  end

  def use_translation(translated, translated_cta, need_reply)
    detected = need_reply ? reply_language : cta_body_language
    message.translations = { original_language(detected) => original_text }
    message.source_language = conversation.language
    message.translation_provider = translator.provider
    message.content = with_quoted_history(translated) if need_reply
    message.content_attributes['email'] = email_content(message.content) if email_reply?
    update_whatsapp_cta_body(translated_cta) if translated_cta.present?
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

  def whatsapp_cta_body
    params = whatsapp_cta_params
    body = params && (params['body'] || params[:body])
    body if body.is_a?(String) && body.present?
  end

  def distinct_cta_body?
    whatsapp_cta_body.present? && whatsapp_cta_body != reply
  end

  def cta_body_language
    return @cta_body_language if defined?(@cta_body_language)

    @cta_body_language = detect(whatsapp_cta_body)
  end

  def translated_cta_body_for(translated_reply, need_cta)
    return if whatsapp_cta_body.blank?
    return translator.translate(whatsapp_cta_body, conversation.language) if need_cta

    distinct_cta_body? ? whatsapp_cta_body : translated_reply
  end

  def over_whatsapp_cta_limit?(translated, translated_cta)
    return false unless whatsapp_cta_reply?

    effective_body = translated_cta.presence || with_quoted_history(translated.to_s)
    effective_body.length > ContentAttributeValidator::WHATSAPP_CTA_BODY_MAX_LENGTH
  end

  def update_whatsapp_cta_body(translated_cta)
    cta_key = message.content_attributes.key?(:whatsapp_cta_url) ? :whatsapp_cta_url : 'whatsapp_cta_url'
    message.content_attributes[cta_key] = whatsapp_cta_params.except(:body, 'body').merge('body' => translated_cta)
  end

  def translate
    translator.translate(reply, conversation.language)
  end

  def original_language(detected_lang)
    detected_lang || agent_locale || account.locale
  end

  def reply_language
    return @reply_language if defined?(@reply_language)

    @reply_language = detect(reply)
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
