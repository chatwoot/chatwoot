module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    include ConversationMonitors::MessageTracking
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async

    before_create :mark_for_translation, if: :translation_wanted?
  end

  # Html mail keeps its markup: only plain text is translated for now.
  def html_email?
    content_attributes.dig('email', 'html_content', 'full').present?
  end

  private

  def mark_for_translation
    content_attributes['translation_pending'] = true
  end

  # Agent replies and templates; bots and automations already write in the contact language.
  def translation_wanted?
    account.auto_translate_enabled? && content.present? && !private? && (template? || (outgoing? && sender.is_a?(User)))
  end
end
