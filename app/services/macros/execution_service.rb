class Macros::ExecutionService
  def initialize(macro, account, conversation)
    @macro = macro
    @account = account
    @conversation = conversation
    Current.executed_by = macro
  end

  def perform
    @macro.actions.each do |action|
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def mute_conversation(_params)
    @conversation.mute!
  end

  def snooze_conversation(_params)
    @conversation.snoozed!
  end

  def resolve_conversation(_params)
    @conversation.resolved!
  end

  def change_status(status)
    @conversation.update!(status: status[0])
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "macro_event.#{@macro.name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false, content_attributes: { automation_rule_id: @macro.id } }
    mb = Messages::MessageBuilder.new(nil, @conversation, params)
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

  def send_email_to_team(_params); end

  def agent_belongs_to_account?(agent_ids)
    @account.agents.pluck(:id).include?(agent_ids[0])
  end

  def team_belongs_to_account?(team_ids)
    @account.team_ids.include?(team_ids[0])
  end

  def conversation_a_tweet?
    return false if @conversation.additional_attributes.blank?

    @conversation.additional_attributes['type'] == 'tweet'
  end
end
