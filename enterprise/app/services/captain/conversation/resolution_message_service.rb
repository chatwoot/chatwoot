class Captain::Conversation::ResolutionMessageService
  pattr_initialize [:conversation!, :assistant!]

  def perform(use_default_message: false)
    return unless assistant.send_inactivity_resolution_message?

    I18n.with_locale(conversation.account.locale) do
      resolution_message = assistant.config['resolution_message'].presence
      resolution_message ||= I18n.t('conversations.activity.auto_resolution_message') if use_default_message
      return if resolution_message.blank?

      conversation.messages.create!(
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: resolution_message,
        sender: assistant
      )
    end
  end
end
