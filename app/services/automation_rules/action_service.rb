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
    increment_trigger_count
  ensure
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

  def send_template(template_params)
    channel = find_channel_by_inbox(@conversation.inbox_id)
    contact = Contact.find(@conversation.contact_id)
    template = template_params[0]
    processed_template = {
                            name: template['name'],
                            namespace: template['namespace'],
                            lang_code:  template['language'],
                            parameters: template['processed_params']&.map { |_, value| { type: 'text', text: value } }
                          }
    channel.send_template(contact.phone_number, processed_template)
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
    end
  end

  def find_channel_by_inbox(inbox_id)
    inbox = Inbox.find(@conversation.inbox_id)
    Channel::Whatsapp.find(inbox.channel_id)
  end

  def increment_trigger_count
    @rule.increment!(:trigger_count)
  end
end 
