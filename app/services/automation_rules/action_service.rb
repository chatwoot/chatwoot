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

  # Sends a pre-approved WhatsApp template as an outgoing message.
  # action_params shape (single-element array containing one config hash):
  #   [{
  #     "inbox_ids":          [Integer, ...],            # WhatsApp inboxes this rule fires on
  #     "template_name":      "appointment_reminder",
  #     "template_language":  "en_US",
  #     "template_namespace": nil,
  #     "template_category":  "MARKETING",
  #     "processed_params":   { "1" => "{{contact.name}}", "2" => "tomorrow" }
  #   }]
  # Placeholders like `{{contact.name}}` are resolved at send time. The action
  # no-ops when the matched conversation isn't on one of the configured inboxes,
  # so the same rule can fan across multiple WhatsApp numbers without firing
  # on unrelated channels.
  def send_whatsapp_template(params)
    config = Array(params).first
    return if config.blank?

    config = config.with_indifferent_access
    return unless whatsapp_template_target?(config)

    processed = AutomationRules::TemplatePlaceholderService.new(@conversation).substitute_processed_params(config[:processed_params])

    builder_params = {
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

    Messages::MessageBuilder.new(nil, @conversation, builder_params).perform
  end

  def whatsapp_template_target?(config)
    return false unless @conversation.inbox&.channel_type == 'Channel::Whatsapp'

    inbox_ids = Array(config[:inbox_ids]).map(&:to_i)
    return false if inbox_ids.blank?

    inbox_ids.include?(@conversation.inbox_id)
  end

  # Rendered body lets us store a readable copy on the message record. The
  # actual outbound payload to WhatsApp is built from processed_params by
  # Whatsapp::SendOnWhatsappService — we don't reach that pipeline ourselves.
  def rendered_template_body(config, processed)
    body = config[:template_body].presence || ''
    return body if processed.blank?

    body.gsub(/{{\s*(\d+)\s*}}/) { |match| processed[Regexp.last_match(1)].presence || match }
  end

  def send_email_to_team(params)
    teams = Team.where(id: params[0][:team_ids])

    teams.each do |team|
      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
    end
  end
end
