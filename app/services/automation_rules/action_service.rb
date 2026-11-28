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
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    blobs = @rule.files.blobs.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs, content_attributes: { automation_rule_id: @rule.id } }
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

  def send_whatsapp_template(params)
    template = params[0]
    # Templates belong to the inbox they were picked from; the rule may match conversations in other inboxes.
    return unless @conversation.inbox_id == template[:inbox_id]
    # Like campaigns, skip when a value renders blank (e.g. a contact without an email): WhatsApp rejects the template.
    return if blank_template_value?(template[:template_params][:processed_params], template_drops)

    message_params = {
      content: template[:content],
      private: false,
      content_attributes: { automation_rule_id: @rule.id },
      template_params: template[:template_params].merge(content_mode: 'raw_template')
    }
    Messages::MessageBuilder.new(nil, @conversation, message_params).perform
  end

  def blank_template_value?(value, drops)
    case value
    when Hash then value.values.any? { |item| blank_template_value?(item, drops) }
    when Array then value.any? { |item| blank_template_value?(item, drops) }
    when String then value.include?('{{') && Liquid::Template.parse(value).render(drops).blank?
    else false
    end
  end

  # The same variables Liquidable renders the template with when the message is created.
  def template_drops
    {
      'contact' => ContactDrop.new(@conversation.contact),
      'agent' => UserDrop.new(@conversation.assignee),
      'conversation' => ConversationDrop.new(@conversation),
      'inbox' => InboxDrop.new(@conversation.inbox),
      'account' => AccountDrop.new(@account)
    }
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    teams = @account.teams.where(id: params[0][:team_ids])

    teams.each do |team|
      break unless @account.within_email_rate_limit?

      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
      @account.increment_email_sent_count
    end
  end
end
