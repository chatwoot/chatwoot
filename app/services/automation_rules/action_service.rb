class AutomationRules::ActionService
  def initialize(rule, conversation)
    @rule = rule
    @conversation = conversation
    @account = @conversation.account
  end

  def perform
    @rule.actions.each do |action, _current_index|
      action = action.with_indifferent_access
      send(action[:action_name], action[:action_params])
    end
  end

  private

  def send_message(message)
    # params = { content: message, private: false }
    # mb = Messages::MessageBuilder.new(@administrator, @conversation, params)
    # mb.perform
  end

  def assign_team(team_ids = [])
    return unless team_belongs_to_account?(team_ids)

    @account.teams.find_by(id: team_ids)
    @conversation.update!(team_id: team_ids[0])
  end

  def assign_best_agents(agent_ids = [])
    return unless agent_belongs_to_account?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)
    @conversation.update_assignee(@agent)
  end

  def add_label(labels = [])
    @conversation.add_labels(labels)
  end

  def send_email_to_team(params)
    team = Team.find(params[:team_ids][0])

    case @rule.event_name
    when 'conversation_created', 'conversation_status_changed'
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[:message])
    when 'conversation_updated'
      TeamNotifications::AutomationNotificationMailer.conversation_updated(@conversation, team, params[:message])
    when 'message_created'
      TeamNotifications::AutomationNotificationMailer.message_created(@conversation, team, params[:message])
    end
  end

  def administrator
    @administrator ||= @account.administrators.first
  end

  def agent_belongs_to_account?(agent_ids)
    @account.agents.pluck(:id).include?(agent_ids[0])
  end

  def team_belongs_to_account?(team_ids)
    @account.team_ids.include?(team_ids[0])
  end
end
