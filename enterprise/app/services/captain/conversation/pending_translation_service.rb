class Captain::Conversation::PendingTranslationService
  include EmailHelper

  def initialize(message:)
    @message = message
  end

  def perform
    return stamp_language if message.incoming?

    follow_latest_incoming if message.template? && conversation.language.blank?
    translatable? ? translate_outgoing : store
  end

  private

  attr_reader :message

  delegate :conversation, :account, :inbox, to: :message

  def translate_outgoing
    translated = translate(reply_text)
    return store if translated == reply_text && !written_in_another_language?
    return store(translation_failed: true) if translated.blank? || translated == reply_text

    store(content: with_quoted_history(translated), translations: { source_locale => agent_text }, source_language: conversation.language)
  end

  # The thread follows the contact's latest language, so replies go out in it.
  def stamp_language
    language = language_of(message)
    store(source_language: language)
    follow(language)
  end

  # A greeting is created together with the first message of the thread, whose own job may still be stamping it.
  def follow_latest_incoming
    latest = conversation.messages.incoming.order(:id).last
    follow(language_of(latest)) if latest
  end

  def follow(language)
    return if language.blank? || conversation.language == language

    conversation.update!(additional_attributes: conversation.additional_attributes.merge(conversation_language: language))
  end

  def language_of(incoming)
    detect(incoming.content) if detectable?(incoming)
  end

  def detectable?(incoming)
    (incoming.text? || incoming.incoming_email?) && !incoming.auto_reply_email? && !incoming.html_email?
  end

  def translatable?
    return false if conversation.language.blank?
    return true if message.template?

    message.text? && message.content_attributes['forwarded_message_id'].blank? && message.additional_attributes.to_h['template_params'].blank?
  end

  # The translator returns a reply already in the contact language unchanged, and now and then gives up on one that is not.
  def written_in_another_language?
    detected_language.present? && !Captain::Llm::MessageTranslationService.same_language?(detected_language, conversation.language)
  end

  def store(content: nil, **attributes)
    content_attributes = message.content_attributes.except('translation_pending').merge(attributes.compact.deep_stringify_keys)
    return message.update!(content_attributes: content_attributes) if content.nil?

    content_attributes['email'] = email_content(content) if inbox.email?
    message.update!(content: content, content_attributes: content_attributes)
  end

  # The mailer sends the stored html, so it is rendered again from the translated text.
  def email_content(content)
    text = normalize_email_body(content)
    html = render_email_html(text)
    message.content_attributes['email']
           .merge('html_content' => { 'full' => html, 'reply' => html }, 'text_content' => { 'full' => text, 'reply' => text })
  end

  # The email reply box appends the quoted history as markdown quote lines; only the text above them is the agent's reply.
  def quoted_history
    @quoted_history ||= inbox.email? ? message.content[/^>.*\z/m].to_s : ''
  end

  def reply_text
    @reply_text ||= quoted_history.blank? ? message.content : message.content.delete_suffix(quoted_history).strip
  end

  def with_quoted_history(translated)
    quoted_history.blank? ? translated : "#{translated.strip}\n\n#{quoted_history}"
  end

  # Agents keep their own text; for email it is rendered like the sent mail so the quoted history stays collapsed.
  def agent_text
    inbox.email? ? render_email_html(normalize_email_body(message.content)) : message.content
  end

  def translate(content)
    response = Captain::Llm::MessageTranslationService.new(account: account, texts: [content], target_language: conversation.language,
                                                           conversation_display_id: conversation.display_id).perform
    Rails.logger.warn("[AutoTranslate] reply sent as written in conversation #{conversation.display_id}: #{response[:error]}") if response[:error]
    response[:message]&.first
  end

  def detect(text)
    Captain::Llm::LanguageDetectionService.new(account: account, text: text).language
  end

  def detected_language
    return @detected_language if defined?(@detected_language)

    @detected_language = detect(reply_text)
  end

  def source_locale
    detected_language || agent_locale || account.locale
  end

  def agent_locale
    message.sender.ui_settings['locale'].presence if message.sender.is_a?(User)
  end
end
