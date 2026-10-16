# Translates an agent reply into the contact language before the channel sends it; the typed text stays on the message for agents.
class Captain::Conversation::ReplyTranslationService
  include EmailHelper

  def initialize(message:)
    @message = message
  end

  def perform
    translated = translate(reply_text)
    # Unchanged and undetectable, a short reply was already in the contact language; unchanged but detected, the model gave up.
    return store if translated == reply_text && detected_language.blank?
    return store(translation_failed: true) if translated.blank? || translated == reply_text

    store(content: with_quoted_history(translated), translations: { source_locale => agent_text }, source_language: conversation.language)
  end

  private

  attr_reader :message

  delegate :conversation, :account, :inbox, to: :message

  def store(content: nil, **attributes)
    content_attributes = message.content_attributes.except('translation_pending').merge(attributes.deep_stringify_keys)
    return message.update!(content_attributes: content_attributes) if content.nil?

    content_attributes['email'] = email_content(content) if inbox.email?
    message.update!(content: content, content_attributes: content_attributes)
  end

  # The mailer sends the stored html, so it is rendered again from the translated text like the builder does.
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

  def detected_language
    return @detected_language if defined?(@detected_language)

    @detected_language = Captain::Llm::LanguageDetectionService.new(account: account, text: reply_text).language
  end

  # The language the agent actually wrote in; the profile language is the fallback for texts too short to detect.
  def source_locale
    detected_language || message.sender.ui_settings['locale'].presence || account.locale
  end
end
