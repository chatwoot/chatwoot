module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    include ConversationMonitors::MessageTracking
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async

    # SendReplyJob handles a flagged message right after the insert; the flag keeps the dashboard and the widget waiting.
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

  def translation_wanted?
    account.auto_translate_enabled? && content.present? && !private? && (incoming? || outgoing_to_translate?)
  end

  # Bots and automations already write in the contact language.
  def outgoing_to_translate?
    template? || (conversation.language.present? && sender.is_a?(User))
  end
end
