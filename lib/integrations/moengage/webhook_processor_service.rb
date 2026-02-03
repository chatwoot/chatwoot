class Integrations::Moengage::WebhookProcessorService
  # MoEngage Connector Campaigns allow fully customizable payloads.
  # These are suggested event names that Chatwoot will recognize.
  SUPPORTED_EVENTS = %w[
    cart_abandoned
    checkout_abandoned
    browse_abandoned
    custom_event
    campaign_triggered
  ].freeze

  def initialize(hook:, payload:)
    @hook = hook
    @payload = payload.with_indifferent_access
    @account = hook.account
    @settings = hook.settings.with_indifferent_access
  end

  def perform
    return unless valid_event?

    find_or_create_contact
    return unless @contact

    create_conversation_with_context
    trigger_ai_response if ai_response_enabled?

    log_success
  rescue StandardError => e
    log_error(e)
    raise
  end

  private

  attr_reader :hook, :payload, :account, :settings

  def valid_event?
    event_name = payload[:event_name] || payload[:event_type]
    SUPPORTED_EVENTS.include?(event_name) || payload[:campaign].present?
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
    event_name = payload[:event_name] || 'Campaign Triggered'
    event_attrs = payload[:event_attributes] || {}

    parts = ["MoEngage Event: #{event_name.to_s.titleize}"]

    parts << "Product: #{event_attrs[:product_name]}" if event_attrs[:product_name].present?
    parts << "Cart Value: #{event_attrs[:cart_value]}" if event_attrs[:cart_value].present?
    parts << "Items: #{event_attrs[:items_count]}" if event_attrs[:items_count].present?

    parts.join("\n")
  end

  def inbox
    @inbox ||= account.inboxes.find(settings[:default_inbox_id])
  end

  def ai_response_enabled?
    settings[:enable_ai_response] && settings[:ai_agent_id].present?
  end

  def trigger_ai_response
    agent_bot = account.agent_bots.find_by(id: settings[:ai_agent_id])
    return unless agent_bot

    @conversation.update!(assignee_agent_bot: agent_bot, assignee: nil)
  rescue StandardError => e
    Rails.logger.error("MoEngage AI response trigger failed: #{e.message}")
  end

  def log_success
    Rails.logger.info(
      "MoEngage webhook processed: event=#{payload[:event_name]} " \
      "contact=#{@contact&.id} conversation=#{@conversation&.id}"
    )
  end

  def log_error(error)
    Rails.logger.error(
      "MoEngage webhook error: #{error.message} " \
      "payload=#{payload.to_json}"
    )
  end
end
