class AgentNotifications::CustomMailer < ApplicationMailer

  def notification_email(conversation, recipient, template)
    raise ArgumentError, "Parameter missing" if conversation.nil? || recipient.nil? || template.nil?

    @conversation = conversation
    @account = conversation.account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    recipients = if @account.suspended?
                   super_admin_emails(@account)
                 else
                   [recipient.email]
                 end
    
    return if recipients.blank?

    @recipient = recipient
    @template = template
    
    mail(
      to: recipients,
      subject: @template.subject || 'Notification from Cruise Control',
    )
  end
end
