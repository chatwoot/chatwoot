class Integrations::Calendly::WebhookProcessorService
  E164_REGEX = /\A\+[1-9]\d{1,14}\z/

  def initialize(hook:, event:, payload:)
    @hook = hook
    @event = event
    @payload = payload
    @account = hook.account
  end

  def perform
    case @event
    when 'invitee.created'
      handle_invitee_created
    when 'invitee.canceled'
      handle_invitee_canceled
    end
  end

  private

  def handle_invitee_created
    contact = find_or_create_contact(@payload['email'], @payload['name'])
    return if contact.blank?

    event_details = fetch_event_details(@payload['event'])
    return if event_details.blank?

    is_reschedule = @payload['old_invitee'].present?
    conversation = find_or_create_conversation_for_contact(contact)
    return if conversation.blank?

    activity_text = build_booking_message(event_details, is_reschedule)
    create_activity_message(conversation, activity_text)

    event_type = is_reschedule ? 'rescheduled' : 'booked'
    send_notification(conversation, event_type, event_details, contact)
  end

  def handle_invitee_canceled
    # Skip if this is part of a reschedule (the created event handles the message)
    return if @payload['new_invitee'].present?

    contact = find_contact(@payload['email'])
    return if contact.blank?

    event_details = fetch_event_details(@payload['event'])
    conversation = find_or_create_conversation_for_contact(contact)
    return if conversation.blank?

    event_name = event_details&.dig('name') || 'Meeting'
    create_activity_message(conversation, "Meeting canceled: #{event_name} — #{format_time(event_details&.dig('start_time'))}")

    send_notification(conversation, 'canceled', event_details, contact,
                      cancellation_reason: @payload['cancellation']&.dig('reason'))
  end

  def find_or_create_contact(email, name)
    contact = find_contact(email)
    return contact if contact.present?

    # Create only if we have an email (phone-only contacts should already exist via their channel)
    return if email.blank?

    @account.contacts.create(email: email, name: name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Calendly: Failed to create contact: #{e.message}")
    nil
  end

  def find_contact(email)
    contact = @account.contacts.from_email(email) if email.present?
    return contact if contact.present?

    phone = extract_phone_number
    @account.contacts.find_by(phone_number: phone) if phone.present?
  end

  def extract_phone_number
    @payload['questions_and_answers']&.each do |qa|
      answer = qa['answer'].to_s.strip
      return answer if answer.match?(E164_REGEX)
    end
  end

  def find_or_create_conversation_for_contact(contact)
    existing = @account.conversations
                       .where(contact_id: contact.id)
                       .where.not(status: :resolved)
                       .order(last_activity_at: :desc)
                       .first
    return existing if existing.present?

    create_conversation_for_contact(contact)
  end

  def create_conversation_for_contact(contact)
    contact_inbox = contact.contact_inboxes.joins(:conversations)
                           .order('conversations.last_activity_at DESC')
                           .first || contact.contact_inboxes.last
    return if contact_inbox.blank?

    ::Conversation.create!(
      account_id: @account.id, inbox_id: contact_inbox.inbox_id,
      contact_id: contact.id, contact_inbox_id: contact_inbox.id
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Calendly: Failed to create conversation: #{e.message}")
    nil
  end

  def send_notification(conversation, event_type, event_details, contact, cancellation_reason: nil)
    if whatsapp_needs_template?(conversation)
      send_template_notification(conversation, event_type, event_details, contact)
    else
      send_ai_notification(conversation, event_type, event_details, contact, cancellation_reason)
    end
  rescue StandardError => e
    Rails.logger.error("Calendly: Notification failed: #{e.message}")
  end

  def send_template_notification(conversation, event_type, event_details, contact)
    template_name = @hook.settings&.dig('calendly_templates', event_type)
    if template_name.blank?
      Rails.logger.warn("Calendly: No WhatsApp template configured for '#{event_type}' — skipping notification")
      return
    end

    params = build_template_message_params(template_name, event_type, event_details, contact)
    message = Messages::MessageBuilder.new(nil, conversation, params).perform
    ::SendReplyJob.perform_later(message.id) if message&.persisted?
  end

  def build_template_message_params(template_name, event_type, event_details, contact)
    {
      content: build_booking_message(event_details, event_type == 'rescheduled'),
      message_type: :outgoing,
      private: false,
      template_params: {
        'name' => template_name, 'language' => 'en',
        'processed_params' => { 'body' => {
          '1' => contact.name.to_s.split.first || 'there',
          '2' => event_details&.dig('name') || 'Meeting',
          '3' => format_time(event_details&.dig('start_time'))
        } }
      }
    }
  end

  def send_ai_notification(conversation, event_type, event_details, contact, cancellation_reason)
    assistant = conversation.aloo_assistant
    return unless assistant&.active?

    Aloo::Current.set_from_conversation(conversation)
    content = generate_notification(event_type, event_details, contact, cancellation_reason)
    return if content.blank?

    message = create_ai_message(conversation, assistant, content)
    ::SendReplyJob.perform_later(message.id) if message&.persisted?
  ensure
    Aloo::Current.reset
  end

  def generate_notification(event_type, event_details, contact, cancellation_reason)
    result = CalendlyNotificationAgent.call(
      event_type: event_type,
      event_name: event_details&.dig('name') || 'Meeting',
      event_time: format_time(event_details&.dig('start_time')),
      contact_name: contact.name.to_s.split.first || 'there',
      cancellation_reason: cancellation_reason
    )
    result.content if result.success?
  end

  def create_ai_message(conversation, assistant, content)
    Messages::MessageBuilder.new(
      assistant, conversation,
      { content: content, message_type: :outgoing, private: false,
        content_attributes: { 'aloo_generated' => true, 'aloo_assistant_id' => assistant.id } }
    ).perform
  end

  def whatsapp_needs_template?(conversation)
    conversation.inbox&.channel_type == 'Channel::Whatsapp' && !conversation.can_reply?
  end

  def fetch_event_details(event_uri)
    return if event_uri.blank?

    uuid = event_uri.split('/').last
    api_client.get_scheduled_event(uuid)
  rescue StandardError => e
    Rails.logger.error("Calendly: Failed to fetch event details: #{e.message}")
    nil
  end

  def build_booking_message(event_details, is_reschedule)
    label = is_reschedule ? 'rescheduled' : 'booked'
    "Meeting #{label}: #{event_details['name'] || 'Meeting'} — #{format_time(event_details['start_time'])}"
  end

  def create_activity_message(conversation, content)
    conversation.messages.create!(account_id: @account.id, inbox_id: conversation.inbox_id, message_type: :activity, content: content)
  end

  def format_time(iso_time)
    return 'Time TBD' if iso_time.blank?

    Time.zone.parse(iso_time).strftime('%B %d, %Y at %I:%M %p %Z')
  rescue StandardError
    iso_time
  end

  def api_client
    @api_client ||= Integrations::Calendly::ApiClient.new(@hook)
  end
end
