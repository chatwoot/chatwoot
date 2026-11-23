class Captain::Conversation::AgentMessageTranslationService
  include EmailHelper

  MAX_EMAIL_BODY_LENGTH = 150_000

  pattr_initialize [:message!]

  def perform
    translate_message
    message.content_attributes.delete('translation_pending')
    message.save!
  end

  private

  delegate :conversation, :account, :inbox, to: :message

  # SendReplyJob runs this before the channel send, so an error here would hold the reply back for good.
  # A failed translation sends the reply as written and flags it instead.
  def translate_message
    detect_contact_language
    if conversation.language.present?
      translate_reply
    elsif translator.failed?
      # Detection failed, so the contact's language is unknown and the reply goes out as written.
      message.translation_failed = true
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    message.translation_failed = true
  end

  def detect_contact_language
    contact_message = conversation.messages.incoming.where(content_type: %w[text incoming_email]).where.not(content: [nil, '']).order(:id).last
    return unless contact_message

    Captain::Conversation::MessageLanguageService.new(conversation: conversation, message: contact_message,
                                                      translator: translator).perform
  end

  def translate_reply
    return if Captain::Llm::MessageTranslationService.same_language?(reply_language, conversation.language)

    translated = translate
    if translated.present? && translated != reply
      use_translation(translated)
    elsif translated.blank? || reply_language.present?
      message.translation_failed = true
    end
  end

  def use_translation(translated)
    translated_body = with_quoted_history(translated)
    if email_body_too_long?(translated_body)
      # A translation that pushes the message past the limit is not sent; the
      # reply goes out as written instead.
      message.translation_failed = true
      return
    end

    message.translations = { original_language => original_text }
    message.source_language = conversation.language
    message.translation_provider = translator.provider
    # The reply content no longer carries the quoted thread, so keep it out of
    # the stored content and append it only to the email that goes out.
    message.content = translated_content(translated, translated_body)
    message.content_attributes['email'] = email_content(translated_body) if email_reply?
  end

  def translate
    translator.translate(reply, conversation.language)
  end

  def original_language
    reply_language || agent_locale || account.locale
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
    @quoted_history ||= stored_quoted_history.presence || legacy_quoted_history
  end

  # Replies created before the quoted thread was split out still carry it at
  # the end of the content.
  def legacy_quoted_history
    inbox.email? ? message.content[/^>.*\z/m].to_s : ''
  end

  # Newer replies store the thread only in the email attributes: the full text
  # is the reply followed by the quoted suffix.
  def stored_quoted_history
    return '' unless inbox.email?

    explicit = stored_email_attributes[:quoted_content] || stored_email_attributes['quoted_content']
    return explicit.to_s.sub(/\A\n+/, '') if explicit.present?

    stored_full = stored_email_text_content
    reply = normalize_email_body(message.content)
    return '' if stored_full.blank? || reply.blank? || !stored_full.start_with?(reply)

    stored_full.delete_prefix(reply).sub(/\A\n+/, '')
  end

  def stored_email_attributes
    message.content_attributes[:email] || message.content_attributes['email'] || {}
  end

  def translated_content(translated, translated_body)
    stored_quoted_history.present? ? translated : translated_body
  end

  def email_body_too_long?(body)
    email_reply? && body.length > MAX_EMAIL_BODY_LENGTH
  end

  def stored_email_text_content
    text_content = stored_email_attributes[:text_content] || stored_email_attributes['text_content'] || {}
    text_content[:full] || text_content['full']
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
