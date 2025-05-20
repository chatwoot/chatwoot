class AgentNotifications::ConversationHandoffMailer < ApplicationMailer
  def notify_handoff(conversation)
    return unless smtp_config_set_or_development?

    @account = conversation.account
    return if @account.agents.blank?

    @conversation   = conversation
    @action_url     = conversation_url(@conversation)

    subject = "Sales Alert: New Conversation Handoff - #{@account.name} - #{conversation.display_id}"

    send_mail_with_liquid(
      to: agents_emails,
      subject: subject
    )
  end

  private

  def agents_emails
    Current.account.agents.pluck(:email)
  end

  def liquid_droppables
    super.merge!({
                   conversation: @conversation,
                   inbox: @conversation.inbox,
                   account: @account
                 })
  end
end
