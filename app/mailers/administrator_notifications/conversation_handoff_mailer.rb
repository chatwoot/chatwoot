class AdministratorNotifications::ConversationHandoffMailer < AdministratorNotifications::BaseMailer
  def notify_handoff(conversation)
    return unless smtp_config_set_or_development?

    @conversation   = conversation
    @account        = conversation.account
    @action_url     = conversation_url(@conversation)

    subject = "Conversation Handoff for account #{@account.name} on platform #{@conversation.inbox.name}"

    send_notification(
      subject,
      to: admin_emails,
      action_url: @action_url,
      meta: {
        conversation_id: @conversation.display_id,
        inbox: @conversation.inbox.name
      }
    )
  end

  private

  def liquid_droppables
    super.merge!({
                   conversation: @conversation,
                   inbox: @conversation.inbox,
                   account: @account
                 })
  end
end
