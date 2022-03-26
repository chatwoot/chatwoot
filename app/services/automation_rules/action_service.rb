class AutomationRules::ActionService
  def initialize(rule, account, conversation)
    @rule = rule
    @account = account
    @conversation = conversation
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

  def send_email_transcript(emails)
    emails.each do |email|
      ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, email)&.deliver_later
    end
  end

  def mute_conversation(_params)
    @conversation.mute!
  end

  def snooze_conversation(_params)
    @conversation.ensure_snooze_until_reset
  end

  def change_status(status)
    @conversation.update!(status: status[0])
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "automation_event: #{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message)
    return if @rule.event_name == 'message_created'

    params = { content: message[0], private: false }
    mb = Messages::MessageBuilder.new(@administrator, @conversation, params)
    mb.perform
  end

  def assign_team(team_ids = [])
    return unless team_belongs_to_account?(team_ids)

    @conversation.update!(team_id: team_ids[0])
  end

  def assign_best_agent(agent_ids = [])
    return unless agent_belongs_to_account?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)

    @conversation.update!(assignee_id: @agent.id) if @agent.present?
  end

  def add_label(labels)
    return if labels.empty?

    @conversation.add_labels(labels)
  end

  def send_email_to_team(params)
    team = Team.find(params[:team_ids][0])

    case @rule.event_name
    when 'conversation_created', 'conversation_status_changed'
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[:message])&.deliver_now
    when 'conversation_updated'
      TeamNotifications::AutomationNotificationMailer.conversation_updated(@conversation, team, params[:message])&.deliver_now
    when 'message_created'
      TeamNotifications::AutomationNotificationMailer.message_created(@conversation, team, params[:message])&.deliver_now
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
