class AutomationRules::ActionService
  def initialize(rule, account, conversation_ids)
    @rule = rule
    @account = account
    @conversations = Conversation.where(id: conversation_ids)
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
    # mb = Messages::MessageBuilder.new(@administrator, @conversations, params)
    # mb.perform
  end

  def assign_team(team_ids = [])
    return unless team_belongs_to_account?(team_ids)

    @account.teams.find_by(id: team_ids)
    @conversations.update_all(team_id: team_ids[0])
  end

  def assign_best_agents(agent_ids = [])
    return unless agent_belongs_to_account?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)
    @conversations.update_all(assignee_id: @agent.id) if @agent.present?
    # @conversations.each do |conversation|
    #   conversation.update_assignee(@agent)
    # end
  end

  def add_label(labels = [])
    @conversations.each do |conversation|
      conversation.add_labels(labels)
    end
  end

  def send_email_to_team(params)
    team = Team.find(params[:team_ids][0])

    case @rule.event_name
    when 'conversation_created', 'conversation_status_changed'
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversations, team, params[:message])
    when 'conversation_updated'
      TeamNotifications::AutomationNotificationMailer.conversation_updated(@conversations, team, params[:message])
    when 'message_created'
      TeamNotifications::AutomationNotificationMailer.message_created(@conversations, team, params[:message])
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
