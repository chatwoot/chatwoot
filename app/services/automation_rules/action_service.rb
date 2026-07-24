class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation)
    super(conversation)
    @rule = rule
    @account = account
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @conversation.reload
      action = action.with_indifferent_access
      begin
        execute_action(action)
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def execute_action(action)
    name = action[:action_name].to_s
    if %w[send_message send_attachment].include?(name)
      send(name, action[:action_params], action[:delivery])
    else
      send(name, action[:action_params])
    end
  end

  def send_attachment(blob_ids, delivery = nil)
    return if conversation_a_tweet?

    return unless @rule.files.attached?

    blobs = ActiveStorage::Blob.where(id: blob_ids)
    return if blobs.blank?

    schedule_or_send_outbound(
      delivery: delivery,
      blob_ids: blobs.map(&:id)
    ) do
      Messages::MessageBuilder.new(nil, @conversation, attachment_message_params(blobs)).perform
    end
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message, delivery = nil)
    return if conversation_a_tweet?

    content = message.is_a?(Array) ? message[0] : message
    schedule_or_send_outbound(
      delivery: delivery,
      content: content,
      automation_rule_id: @rule.id
    ) do
      params = { content: content, private: false, content_attributes: { automation_rule_id: @rule.id } }
      Messages::MessageBuilder.new(nil, @conversation, params).perform
    end
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      break unless @account.within_email_rate_limit?

      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
      @account.increment_email_sent_count
    end
  end

  # Run a saved macro's actions on this conversation (one level deep — no nested execute_macro).
  def execute_macro(macro_ids)
    return if @executing_macro

    macro_id = Array(macro_ids).first
    return if macro_id.blank?

    macro = @account.macros.find_by(id: macro_id)
    return if macro.blank?

    user = macro.created_by || @account.administrators.order(:id).first || @account.users.order(:id).first
    return if user.blank?

    @executing_macro = true
    Macros::ExecutionService.new(macro, @conversation, user).perform
  ensure
    @executing_macro = false
  end

  def enter_flow(flow_refs)
    return unless @account.feature_enabled?('flows_v1')
    return if @conversation.in_flow?

    ref = Array(flow_refs).first
    return if ref.blank?

    flow = @account.flows.active.find_by(id: ref) || @account.flows.active.find_by(name: ref.to_s)
    return if flow.blank?

    Flows::StartService.new(
      account: @account,
      conversation: @conversation,
      flow: flow,
      trigger: 'automation_rule'
    ).perform
  end
end
