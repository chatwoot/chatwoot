class MessageTemplates::Template::AutoResolvePending < MessageTemplates::Template::AutoResolve
  def perform
    return if conversation.account.auto_resolve_pending_message.blank?

    if within_messaging_window?
      conversation.messages.create!(auto_resolve_message_params)
    else
      create_auto_resolve_not_sent_activity_message
    end
  end

  private

  def auto_resolve_message_params
    super.merge(content: account.auto_resolve_pending_message)
  end
end
