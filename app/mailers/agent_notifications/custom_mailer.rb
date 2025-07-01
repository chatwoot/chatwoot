class AgentNotifications::CustomMailer < ApplicationMailer

  def notification_email(conversation, recipient, template)
    raise ArgumentError, "Parameter missing" if conversation.nil? || recipient.nil? || template.nil?

    @conversation = conversation
    @recipient = recipient
    @template = template
    
    mail(
      to: @recipient.email,
      subject: @template.subject || 'Notification from Cruise Control',
    )
  end
end
