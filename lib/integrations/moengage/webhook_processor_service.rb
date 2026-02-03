class Integrations::Moengage::WebhookProcessorService
  def initialize(hook:, payload:, event_log: nil)
    @hook = hook
    @payload = payload.with_indifferent_access
    @account = hook.account
    @settings = hook.settings.with_indifferent_access
    @event_log = event_log
  end

  def perform
    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    unless valid_payload?
      log_skipped('Invalid payload: missing event_name or campaign')
      return
    end

    find_or_create_contact
    unless @contact
      log_skipped('Contact not found and auto_create_contact is disabled')
      return
    end

    create_conversation_with_context
    trigger_ai_response if should_trigger_ai?

    log_success
  rescue StandardError => e
    log_error(e)
    raise
  end

  private

  attr_reader :hook, :payload, :account, :settings, :event_log

  # Accept any payload that has an event name or campaign - MoEngage allows custom events
  def valid_payload?
    event_name.present? || payload[:campaign].present?
  end

  def event_name
    payload[:event_name] || payload[:event_type]
  end

  def find_or_create_contact
    @contact = find_existing_contact || create_contact
  end

  def find_existing_contact
    customer = payload[:customer] || {}

    contact = nil
    contact ||= find_by_identifier(customer[:customer_id]) if customer[:customer_id].present?
    contact ||= find_by_email(customer[:email]) if customer[:email].present?
    contact ||= find_by_phone(customer[:phone]) if customer[:phone].present?

    update_contact_attributes(contact, customer) if contact
    contact
  end

  def find_by_identifier(identifier)
    account.contacts.find_by(identifier: identifier)
  end

  def find_by_email(email)
    account.contacts.find_by(email: email)
  end

  def find_by_phone(phone)
    normalized_phone = normalize_phone(phone)
    account.contacts.find_by(phone_number: normalized_phone)
  end

  def normalize_phone(phone)
    phone.to_s.gsub(/[^\d+]/, '')
  end

  def create_contact
    return nil unless settings[:auto_create_contact]

    customer = payload[:customer] || {}

    Contact.create!(
      account: account,
      name: customer[:name] || build_name(customer),
      email: customer[:email],
      phone_number: normalize_phone(customer[:phone]),
      identifier: customer[:customer_id],
      custom_attributes: build_custom_attributes(customer)
    )
  end

  def build_name(customer)
    [customer[:first_name], customer[:last_name]].compact.join(' ').presence || 'MoEngage Contact'
  end

  def build_custom_attributes(customer)
    base_attrs = {
      'moengage_customer_id' => customer[:customer_id],
      'source' => 'moengage'
    }

    additional_attrs = customer[:attributes] || {}
    base_attrs.merge(additional_attrs.stringify_keys)
  end

  def update_contact_attributes(contact, customer)
    attrs = contact.custom_attributes || {}
    attrs['moengage_customer_id'] ||= customer[:customer_id]
    attrs['last_moengage_event'] = payload[:event_name]
    attrs['last_moengage_event_at'] = Time.current.iso8601

    contact.update!(custom_attributes: attrs)
  end

  def create_conversation_with_context
    @contact_inbox = find_or_create_contact_inbox
    @conversation = find_open_conversation || create_conversation

    add_event_context_message
  end

  def find_or_create_contact_inbox
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: inbox,
      source_id: @contact.identifier || @contact.email
    ).perform
  end

  def find_open_conversation
    @contact_inbox.conversations.open.order(created_at: :desc).first
  end

  def create_conversation
    Conversation.create!(
      account: account,
      inbox: inbox,
      contact: @contact,
      contact_inbox: @contact_inbox,
      custom_attributes: conversation_custom_attributes
    )
  end

  def conversation_custom_attributes
    {
      'moengage_event' => payload[:event_name],
      'moengage_campaign_id' => payload.dig(:campaign, :id),
      'moengage_campaign_name' => payload.dig(:campaign, :name),
      'triggered_at' => payload[:triggered_at]
    }.compact
  end

  def add_event_context_message
    context = build_event_context
    return if context.blank?

    @conversation.messages.create!(
      account: account,
      inbox: inbox,
      message_type: :activity,
      content: context
    )
  end

  def build_event_context
    display_name = event_name.presence || 'Campaign Triggered'
    event_attrs = payload[:event_attributes] || {}

    parts = ["MoEngage Event: #{display_name.to_s.titleize}"]

    parts << "Product: #{event_attrs[:product_name]}" if event_attrs[:product_name].present?
    parts << "Cart Value: #{event_attrs[:cart_value]}" if event_attrs[:cart_value].present?
    parts << "Items: #{event_attrs[:items_count]}" if event_attrs[:items_count].present?

    parts.join("\n")
  end

  def inbox
    @inbox ||= account.inboxes.find(settings[:default_inbox_id])
  end

  def should_trigger_ai?
    ai_response_enabled? && inbox_has_ai_agent?
  end

  def ai_response_enabled?
    settings[:enable_ai_response] == true
  end

  def inbox_has_ai_agent?
    inbox.active_aloo_assistant? || (inbox.agent_bot_inbox&.active? && inbox.agent_bot.present?)
  end

  def trigger_ai_response
    if inbox.active_aloo_assistant?
      trigger_aloo_proactive_outreach
    elsif inbox.agent_bot.present?
      trigger_agent_bot_webhook
    end
  rescue StandardError => e
    Rails.logger.error("MoEngage AI response trigger failed: #{e.message}")
  end

  def trigger_aloo_proactive_outreach
    event_context = {
      event_name: payload[:event_name],
      event_attributes: payload[:event_attributes],
      campaign: payload[:campaign],
      customer: payload[:customer]
    }
    Aloo::ProactiveOutreachJob.perform_later(@conversation.id, event_context)
  end

  def trigger_agent_bot_webhook
    agent_bot = inbox.agent_bot
    return unless agent_bot

    payload_data = @conversation.webhook_data.merge(event: 'conversation_opened')
    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload_data)
  end

  def log_success
    update_event_log(
      status: :success,
      response_data: {
        contact_id: @contact&.id,
        conversation_id: @conversation&.id,
        ai_triggered: should_trigger_ai?
      }
    )

    Rails.logger.info(
      "MoEngage webhook processed: event=#{payload[:event_name]} " \
      "contact=#{@contact&.id} conversation=#{@conversation&.id}"
    )
  end

  def log_skipped(reason)
    update_event_log(status: :skipped, error_message: reason)

    Rails.logger.info("MoEngage webhook skipped: #{reason}")
  end

  def log_error(error)
    update_event_log(status: :failed, error_message: error.message)

    Rails.logger.error(
      "MoEngage webhook error: #{error.message} " \
      "payload=#{payload.to_json}"
    )
  end

  def update_event_log(status:, response_data: {}, error_message: nil)
    return unless event_log

    event_log.update(
      status: status,
      response_data: response_data,
      error_message: error_message,
      contact: @contact,
      conversation: @conversation,
      processing_time_ms: calculate_processing_time
    )
  rescue StandardError => e
    Rails.logger.error("Failed to update MoEngage event log: #{e.message}")
  end

  def calculate_processing_time
    return nil unless @start_time

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
    (elapsed * 1000).round
  end
end
