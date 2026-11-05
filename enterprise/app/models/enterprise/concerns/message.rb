module Enterprise::Concerns::Message
  extend ActiveSupport::Concern

  included do
    include ConversationMonitors::MessageTracking
    has_one :call, dependent: :nullify
    has_many :message_reports, class_name: 'Captain::MessageReport', dependent: :destroy_async
    # A deleted message keeps its row with placeholder text.
    scope :not_deleted, -> { where("((messages.content_attributes #>> '{}')::jsonb ->> 'deleted') IS DISTINCT FROM 'true'") }

    before_create :mark_for_translation, if: :translation_enabled?
  end

  private

  def mark_for_translation
    content_attributes['translation_pending'] = true
  end

  # Bots and automations already write in the contact language.
  def translation_enabled?
    account.auto_translate_enabled? && content.present? && !private? && (template? || translatable_agent_reply?)
  end

  # Forwarded messages and WhatsApp templates must go out exactly as they are.
  def translatable_agent_reply?
    outgoing? && sender.is_a?(User) && text? && content_attributes['forwarded_message_id'].blank? &&
      additional_attributes.to_h['template_params'].blank?
  end
end
