class AgentNotifications::ConversationNotificationsMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  layout 'mailer'

  def conversation_creation(conversation, agent)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    subject = "#{@agent.available_name}, A new conversation [ID - #{@conversation.display_id}] has been created in #{@conversation.inbox&.name}."
    mail(to: @agent.email, subject: subject)
  end

  def conversation_assignment(conversation, agent)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    mail(to: @agent.email, subject: "#{@agent.available_name}, A new conversation [ID - #{@conversation.display_id}] has been assigned to you.")
  end
end
