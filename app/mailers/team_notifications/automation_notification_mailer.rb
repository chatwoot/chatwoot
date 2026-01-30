class TeamNotifications::AutomationNotificationMailer < ApplicationMailer
  def conversation_creation(conversation, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversation
    @account = conversation.account
    ensure_current_account(@account)
    @custom_message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team
  end

  private

  def send_an_email_to_team
    subject = 'This email has been sent via automation rule actions.'
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    
    # If account is suspended, send to SuperAdmins only
    recipients = if @account.suspended?
                   super_admin_emails(@account)
                 else
                   @agents.collect(&:user).pluck(:email)
                 end
    
    return if recipients.blank?
    
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def liquid_droppables
    super.merge!({
                   conversation: @conversation,
                   inbox: @conversation.inbox
                 })
  end

  def liquid_locals
    super.merge!({
                   custom_message: @custom_message
                 })
  end
end
