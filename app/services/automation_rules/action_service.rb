class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation)
    super(conversation)
    @rule = rule
    @account = account
    Rails.logger.info '[AUTOMATION_RULES] 🤖 Initializing AutomationRules::ActionService'
    Rails.logger.info "[AUTOMATION_RULES] Rule: #{rule.id} (#{rule.name})"
    Rails.logger.info "[AUTOMATION_RULES] Conversation: #{conversation.id}"
    Rails.logger.info '[AUTOMATION_RULES] Setting Current.executed_by to rule'
    Current.executed_by = rule
  end

  def perform
    Rails.logger.info "[AUTOMATION_RULES] 🚀 Performing #{@rule.actions.count} actions for rule #{@rule.id}"

    @rule.actions.each_with_index do |action, index|
      @conversation.reload
      action = action.with_indifferent_access
      Rails.logger.info "[AUTOMATION_RULES] Action #{index + 1}: #{action[:action_name]} with params: #{action[:action_params].inspect}"

      begin
        send(action[:action_name], action[:action_params])
        Rails.logger.info "[AUTOMATION_RULES] ✅ Action #{action[:action_name]} completed"
      rescue StandardError => e
        Rails.logger.error "[AUTOMATION_RULES] Action #{action[:action_name]} failed: #{e.message}"
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Rails.logger.info '[AUTOMATION_RULES] 🔄 Resetting Current context'
    Current.reset
  end

  private

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    return unless @rule.files.attached?

    blobs = ActiveStorage::Blob.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
    end
  end
end
