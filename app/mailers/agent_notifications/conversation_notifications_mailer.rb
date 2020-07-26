class AgentNotifications::ConversationNotificationsMailer < ApplicationMailer
  def conversation_creation(conversation, agent)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    subject = "#{@agent.name}, A new conversation [ID - #{@conversation.display_id}] has been created in #{@conversation.inbox&.name}."
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  def conversation_assignment(conversation, agent)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    subject = "#{@agent.name}, A new conversation [ID - #{@conversation.display_id}] has been assigned to you."
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  private

  def droppables
    super.merge({
                  agent: @agent
                })
  end
end
