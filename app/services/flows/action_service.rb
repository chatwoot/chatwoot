# Executes automation/macro-style actions inside a flow step.
# send_message (with optional buttons + typing) is handled by ExecutionService + HumanLikeSendService.
class Flows::ActionService < ActionService
  # Nested flow / macro / SLA / attachments without Flow file storage.
  EXCLUDED = %w[enter_flow execute_macro add_sla send_attachment].freeze

  ALLOWED = %w[
    assign_agent
    assign_team
    remove_assigned_agent
    remove_assigned_team
    add_label
    remove_label
    send_email_to_team
    send_email_transcript
    mute_conversation
    snooze_conversation
    resolve_conversation
    open_conversation
    pending_conversation
    send_webhook_event
    add_private_note
    change_priority
    update_contact_custom_attribute
    update_conversation_custom_attribute
  ].freeze

  def initialize(conversation:, flow_run:)
    super(conversation)
    @flow_run = flow_run
    @account = conversation.account
  end

  def execute(action)
    action = action.with_indifferent_access
    name = action[:action_name].to_s
    return false if EXCLUDED.include?(name) || name == 'send_message'
    return false unless ALLOWED.include?(name)

    send(name, action[:action_params])
    true
  end

  private

  def add_private_note(message)
    return if conversation_a_tweet?

    content = message.is_a?(Array) ? message[0] : message
    params = {
      content: content,
      private: true,
      content_attributes: { flow_run_id: @flow_run.id }
    }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    payload = params.is_a?(Array) ? params[0] : params
    return if payload.blank?

    payload = payload.with_indifferent_access
    teams = Team.where(id: payload[:team_ids])

    teams.each do |team|
      break unless @account.within_email_rate_limit?

      TeamNotifications::AutomationNotificationMailer.conversation_creation(
        @conversation, team, payload[:message]
      )&.deliver_now
      @account.increment_email_sent_count
    end
  end

  def send_webhook_event(webhook_url)
    url = webhook_url.is_a?(Array) ? webhook_url.first : webhook_url
    return if url.blank?

    payload = @conversation.webhook_data.merge(
      event: 'flow.step',
      flow_run_id: @flow_run.id,
      flow_id: @flow_run.flow_id
    )
    WebhookJob.perform_later(url, payload)
  end
end
