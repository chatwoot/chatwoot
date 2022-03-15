class AutomationRules::ActionService
  def initialize(rule, account, conversation_ids)
    @rule = rule
    @account = account
    @conversations = Conversation.where(id: conversation_ids)
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
  ensure
    Current.reset
  end

  private

  def send_email_transcript(email)
    @conversations.each do |conversation|
      ConversationReplyMailer.with(account: conversation.account).conversation_transcript(conversation, email)&.deliver_later
    end
  end

  def mute_conversation(_params)
    @conversations.each(&:mute!)
  end

  def change_status(status)
    @conversations.each do |conversation|
      conversation.update!(status: status[0])
    end
  end

  def send_webhook_events(webhook_url)
    @conversations.each do |conversation|
      payload = conversation.webhook_data.merge(event: "automation_event: #{@rule.event_name}")
      WebhookJob.perform_later(webhook_url, payload)
    end
  end

  def send_message(message)
    return if @rule.event_name == 'message_created'

    params = { content: message[0], private: false }
    @conversations.each do |conversation|
      mb = Messages::MessageBuilder.new(@administrator, conversation, params)
      mb.perform
    end
  end

  def assign_team(team_ids = [])
    return unless team_belongs_to_account?(team_ids)

    @conversations.each do |conversation|
      conversation.update!(team_id: team_ids[0])
    end
  end

  def assign_best_agent(agent_ids = [])
    return unless agent_belongs_to_account?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)

    @conversations.each do |conversation|
      conversation.update!(assignee_id: @agent.id) if @agent.present?
    end
  end

  def add_label(labels)
    @conversations.each do |conversation|
      conversation.add_automation_labels(labels)
    end
  end

  def send_email_to_team(params)
    team = Team.find(params[:team_ids][0])

    case @rule.event_name
    when 'conversation_created', 'conversation_status_changed'
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversations, team, params[:message])&.deliver_now
    when 'conversation_updated'
      TeamNotifications::AutomationNotificationMailer.conversation_updated(@conversations, team, params[:message])&.deliver_now
    when 'message_created'
      TeamNotifications::AutomationNotificationMailer.message_created(@conversations, team, params[:message])&.deliver_now
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
