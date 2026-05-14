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

  # Sends an approved WhatsApp template to the contact's phone number,
  # independent of what channel triggered the rule. Use case: an "I made
  # payment" email comes in, the rule fires on the email conversation, and
  # an acknowledgement template is sent to the same contact via WhatsApp.
  #
  # action_params shape (single-element array containing one config hash):
  #   [{
  #     "inbox_id":           5,                       # WhatsApp inbox to send FROM (required)
  #     "template_name":      "appointment_reminder",
  #     "template_language":  "en_US",
  #     "template_namespace": nil,
  #     "template_category":  "MARKETING",
  #     "template_body":      "Hi {{1}}, ...",         # cached for content rendering
  #     "processed_params":   { "1" => "{{contact.name}}", "2" => "tomorrow" }
  #   }]
  #
  # Skip conditions (logged, no error):
  #   * contact missing or contact.phone_number blank
  #   * configured inbox not found, deleted, or not a WhatsApp channel
  def send_whatsapp_template(params)
    config = Array(params).first&.with_indifferent_access
    return if config.blank?

    target = resolve_whatsapp_target(config)
    return if target.blank?

    processed = AutomationRules::TemplatePlaceholderService.new(@conversation).substitute_processed_params(config[:processed_params])
    Messages::MessageBuilder.new(nil, target, whatsapp_builder_params(config, processed)).perform
  end

  def resolve_whatsapp_target(config)
    inbox = whatsapp_target_inbox(config[:inbox_id])
    return if inbox.blank?

    contact = @conversation.contact
    return if contact.blank? || contact.phone_number.blank?

    contact_inbox = ContactInboxBuilder.new(contact: contact, inbox: inbox).perform
    return if contact_inbox.blank?

    whatsapp_target_conversation(contact_inbox)
  end

  def whatsapp_target_inbox(inbox_id)
    return if inbox_id.blank?

    @account.inboxes.find_by(id: inbox_id, channel_type: 'Channel::Whatsapp')
  end

  def whatsapp_target_conversation(contact_inbox)
    ConversationBuilder.new(params: ActionController::Parameters.new({}), contact_inbox: contact_inbox).perform
  end

  def whatsapp_builder_params(config, processed)
    {
      content: rendered_template_body(config, processed),
      private: false,
      content_attributes: { automation_rule_id: @rule.id },
      template_params: {
        name: config[:template_name],
        namespace: config[:template_namespace],
        language: config[:template_language],
        category: config[:template_category],
        processed_params: processed
      }
    }
  end

  # Rendered body is stored on the message record for the agent UI; the
  # actual outbound payload to WhatsApp is built from processed_params by
  # Whatsapp::SendOnWhatsappService.
  def rendered_template_body(config, processed)
    body = config[:template_body].presence || ''
    return body if processed.blank?

    body.gsub(/{{\s*(\d+)\s*}}/) { |match| processed[Regexp.last_match(1)].presence || match }
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
end
