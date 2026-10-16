module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    include ConversationMonitors::MessageTracking
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async

    before_create :translate_template_content, if: :translate_template_content?
    before_create :detect_language, if: :detect_language?
    before_create :mark_reply_for_translation, if: :reply_to_translate?
    # After the insert: updating the conversation while a built message is still unsaved autosaves it a second time.
    after_create :update_conversation_language, if: :detect_language?
  end

  # Html mail keeps its markup: only plain text is translated for now.
  def html_email?
    content_attributes.dig('email', 'html_content', 'full').present?
  end

  private

  # Templates are translated before the insert because channels send the message as soon as it exists.
  def translate_template_content?
    template? && content.present? && account.auto_translate_enabled? && conversation.language.present? &&
      !Captain::Llm::MessageTranslationService.same_language?(conversation.language, template_language)
  end

  def template_language
    @template_language ||= Captain::Llm::LanguageDetectionService.new(account: account, text: content).language || account.locale
  end

  def translate_template_content
    response = Captain::Llm::MessageTranslationService.new(
      account: account, texts: [content], target_language: conversation.language, conversation_display_id: conversation.display_id
    ).perform
    translated_content = response[:message]&.first
    return if response[:error] || translated_content.blank? || translated_content == content

    self.translations = { template_language => content }
    self.content = translated_content
  end

  # Replies go out through SendReplyJob, which translates them first; the flag keeps the dashboard and the widget waiting.
  def mark_reply_for_translation
    content_attributes['translation_pending'] = true
  end

  # Agent replies only: bots and automations already write in the contact language.
  def reply_to_translate?
    outgoing? && !private? && text? && sender.is_a?(User) && content.present? && translation_wanted?
  end

  def translation_wanted?
    content_attributes['forwarded_message_id'].blank? && additional_attributes.to_h['template_params'].blank? &&
      account.auto_translate_enabled? && conversation.language.present?
  end

  def detect_language?
    incoming? && (text? || incoming_email?) && !auto_reply_email? && !html_email? && account.auto_translate_enabled?
  end

  def detect_language
    language = Captain::Llm::LanguageDetectionService.new(account: account, text: content).language
    content_attributes['source_language'] = language if language.present?
  end

  # The thread follows the contact's latest language, so replies go out in it.
  def update_conversation_language
    language = content_attributes['source_language']
    return if language.blank? || conversation.language == language

    conversation.update!(additional_attributes: conversation.additional_attributes.merge(conversation_language: language))
  end
end
