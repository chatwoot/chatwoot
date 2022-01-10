class TeamNotifications::AutomationNotificationMailer < ApplicationMailer
  def conversation_creation(conversation, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversation
    @message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team
  end

  def conversation_updated(conversation, team)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversation
    @message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team
  end

  def message_created(message, agent)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = message.conversation
    @message = message
    subject = "#{@agent.available_name}, You have been mentioned in conversation [ID - #{@conversation.display_id}]"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: subject)
  end

  private

  def send_an_email_to_team
    @agents.each do |agent|
      subject = "#{@agent.available_name}, A new conversation [ID - #{@conversation.display_id}] has been created in #{@conversation.inbox&.name}."
      @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
      send_mail_with_liquid(to: agent.email, subject: subject)
    end
  end

  def liquid_droppables
    super.merge({
                  user: @agent,
                  conversation: @conversation,
                  inbox: @conversation.inbox,
                  message: @message
                })
  end
end
