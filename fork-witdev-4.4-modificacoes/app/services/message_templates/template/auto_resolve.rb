class MessageTemplates::Template::AutoResolve
  pattr_initialize [:conversation!]

  def perform
    return if conversation.account.auto_resolve_message.blank?

    if within_messaging_window?
      conversation.messages.create!(auto_resolve_message_params)
    else
      create_auto_resolve_not_sent_activity_message
    end
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def within_messaging_window?
    conversation.can_reply?
  end

  def create_auto_resolve_not_sent_activity_message
    content = I18n.t('conversations.activity.auto_resolve.not_sent_due_to_messaging_window')
    activity_message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    }
    ::Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params) if content
  end

  def auto_resolve_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: account.auto_resolve_message
    }
  end
end
