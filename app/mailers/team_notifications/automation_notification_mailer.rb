class TeamNotifications::AutomationNotificationMailer < ApplicationMailer
  def conversation_creation(conversation, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversation
    @custom_message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team and return
  end

  def conversation_updated(conversation, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversation
    @custom_message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team and return
  end

  def message_created(conversation, team, message)
    return unless smtp_config_set_or_development?

    @agents = team.team_members
    @conversation = conversation
    @custom_message = message
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)

    send_an_email_to_team and return
  end

  private

  def send_an_email_to_team
    @agents.each do |agent|
      subject = "#{agent.user.available_name}, This email has been sent via automation rule actions."
      @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
      @agent = agent

      send_mail_with_liquid(to: @agent.user.email, subject: subject)
    end
  end

  def liquid_droppables
    super.merge!({
                   user: @agent.user,
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
