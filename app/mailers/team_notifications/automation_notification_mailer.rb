class TeamNotifications::AutomationNotificationMailer < ApplicationMailer
  def conversation_creation(conversations, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversations[0]
    @message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team and return
  end

  def conversation_updated(conversations, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversations[0]
    @message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team and return
  end

  def message_created(conversations, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversations[0]
    @message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team and return
  end

  private

  def send_an_email_to_team
    @agents.each do |agent|
      subject = "#{agent.user.available_name}, A new conversation [ID - #{@conversation.display_id}] has been created in #{@conversation.inbox&.name}."
      @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
      @agent = agent

      send_mail_with_liquid(to: @agent.user.email, subject: subject)
    end
  end

  def liquid_droppables
    super.merge!({
                   user: @agent.user,
                   message: @message,
                   conversation: @conversation,
                   inbox: @conversation.inbox
                 })
  end
end
