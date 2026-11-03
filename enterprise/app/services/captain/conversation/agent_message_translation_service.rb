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
    return if Captain::Llm::MessageTranslationService.same_language?(reply_language, conversation.language)

    translated = translate
    if translated.present? && translated != reply
      use_translation(translated)
    elsif translated.blank? || reply_language.present?
      message.translation_failed = true
    end
  end

  def use_translation(translated)
    message.translations = { original_language => original_text }
    message.source_language = conversation.language
    message.translation_provider = translator.provider
    message.content = with_quoted_history(translated)
    message.content_attributes['email'] = email_content(message.content) if email_reply?
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
