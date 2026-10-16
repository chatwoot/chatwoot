class Captain::Conversation::AgentMessageTranslationService
  include EmailHelper

  pattr_initialize [:message!]

  def perform
    update_conversation_language
    translate_reply if translatable?

    message.content_attributes.delete('translation_pending')
    message.save!
  end

  private

  delegate :conversation, :account, :inbox, to: :message

  # The conversation language follows the contact's latest message, detected once per message, so a switch midway is picked up.
  def update_conversation_language
    contact_message = conversation.messages.incoming.where.not(content: [nil, '']).order(:id).last
    return if contact_message.blank? || contact_message.source_language.present?

    language = detect(contact_message.content)
    return if language.blank?

    contact_message.update!(source_language: language)
    return if language == conversation.language

    conversation.update!(additional_attributes: conversation.additional_attributes.merge('conversation_language' => language))
  end

  def translatable?
    return false if conversation.language.blank?
    return true if message.template?

    message.text? && message.content_attributes['forwarded_message_id'].blank? && message.additional_attributes.to_h['template_params'].blank?
  end

  # The translator hands back text already in the conversation language unchanged, but sometimes also text it gave up on.
  def written_in_conversation_language?
    reply_language.blank? || Captain::Llm::MessageTranslationService.same_language?(reply_language, conversation.language)
  end

  def translate_reply
    translated = translate(reply)

    if translated.present? && translated != reply
      use_translation(translated)
    elsif translated.blank? || !written_in_conversation_language?
      message.translation_failed = true
    end
  end

  # The agent's own text is kept under translations before the content is replaced.
  def use_translation(translated)
    message.translations = { original_language => original_text }
    message.source_language = conversation.language
    message.content = with_quoted_history(translated)
    message.content_attributes['email'] = email_content(message.content) if inbox.email?
  end

  def translate(text)
    response = Captain::Llm::MessageTranslationService.new(account: account, text: text, target_language: conversation.language,
                                                           conversation_display_id: conversation.display_id).perform
    Rails.logger.warn("[AutoTranslate] reply sent as written in conversation #{conversation.display_id}: #{response[:error]}") if response[:error]
    response[:message]
  end

  def original_language
    reply_language || agent_locale || account.locale
  end

  def reply_language
    return @reply_language if defined?(@reply_language)

    @reply_language = detect(reply)
  end

  def detect(text)
    Captain::Llm::LanguageDetectionService.new(account: account, text: text).language
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
    inbox.email? ? render_email_html(normalize_email_body(message.content)) : message.content
  end

  # The mailer sends the stored html, so it is rendered again from the translated text.
  def email_content(content)
    text = normalize_email_body(content)
    html = render_email_html(text)
    message.content_attributes['email']
           .merge('html_content' => { 'full' => html, 'reply' => html }, 'text_content' => { 'full' => text, 'reply' => text })
  end
end
