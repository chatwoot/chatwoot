class AutomationRules::ContactActionService
  include EmailHelper

  def initialize(rule, account, contact)
    @contact = contact.reload
    @account = @contact.account
    @rule = rule
    @account = account
    @conversations = contact.conversations
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @contact.reload
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

  ### ----- Start of Contact Action Handler ----- ###
  def assign_agent(agent_ids = [])
    return @contact.update!(assignee_id: nil) if agent_ids[0] == 'nil'

    @agent = @account.users.find_by(id: agent_ids)

    @contact.update!(assignee_id: @agent.id) if @agent.present?
    # Update the person assigned to the conversation if nil
    @contact.conversations.where(assignee_id: nil).find_each do |conversation|
      conversation.update(assignee_id: @agent.id)
    end
  end

  def assign_team(team_ids = [])
    return unassign_team if team_ids[0]&.zero?
    # check if team belongs to account only if team_id is present
    # if team_id is nil, then it means that the team is being unassigned
    return unless !team_ids[0].nil? && team_belongs_to_account?(team_ids)

    @contact.update!(team_id: team_ids[0])
  end

  def update_contact_stage(stage_ids = [])
    return unless !stage_ids[0].nil? && stage_belongs_to_account?(stage_ids)

    @contact.update!(stage_id: stage_ids.first)
  end

  def add_label(labels)
    return if labels.empty?

    @contact.reload.add_labels(labels)
  end

  def remove_label(labels)
    return if labels.empty?

    labels = @contact.label_list - labels
    @contact.update(label_list: labels)
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      TeamNotifications::AutomationNotificationMailer
        .contact_creation(
          @contact, team, params[0][:message]
        )&.deliver_now
    end
  end

  def send_webhook_event(webhook_url)
    payload = @contact.webhook_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end
  ### ----- End of Contact Action Handler ----- ###

  def team_belongs_to_account?(team_ids)
    @account.team_ids.include?(team_ids[0])
  end

  def stage_belongs_to_account?(stage_ids)
    @account.stage_ids.include?(stage_ids[0])
  end

  def conversation_a_tweet?(conversation)
    conversation.additional_attributes.present? &&
      conversation.additional_attributes['type'] == 'tweet'
  end
end
