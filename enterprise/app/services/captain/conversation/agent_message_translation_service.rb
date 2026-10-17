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
    if translated.present? && translated != message.content
      use_translation(translated)
    elsif translated.blank? || reply_language.present?
      message.translation_failed = true
    end
  end

  def use_translation(translated)
    message.translations = { original_language => message.content }
    message.source_language = conversation.language
    message.content = translated
    message.content_attributes['email'] = email_content(message.content) if inbox.email?
  end

  def translate
    Captain::Llm::MessageTranslationService.new(
      account: account, text: message.content, target_language: conversation.language, conversation_display_id: conversation.display_id
    ).perform[:message]
  end

  def original_language
    reply_language || agent_locale || account.locale
  end

  def reply_language
    return @reply_language if defined?(@reply_language)

    @reply_language = Captain::Llm::LanguageDetectionService.new(account: account, text: message.content).language
  end

  def agent_locale
    message.sender.ui_settings['locale'].presence if message.sender.is_a?(User)
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
