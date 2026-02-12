class Integrations::Calendly::WebhookProcessorService
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

    conversation = find_conversation_for_contact(contact)
    return if conversation.blank?

    message = build_booking_message(event_details, @payload['old_invitee'].present?)
    create_activity_message(conversation, message)
  end

  def handle_invitee_canceled
    # Skip if this is part of a reschedule (the created event handles the message)
    return if @payload['new_invitee'].present?

    contact = @account.contacts.from_email(@payload['email'])
    return if contact.blank?

    event_details = fetch_event_details(@payload['event'])
    conversation = find_conversation_for_contact(contact)
    return if conversation.blank?

    event_name = event_details&.dig('name') || 'Meeting'
    create_activity_message(conversation, "Meeting canceled: #{event_name} — #{format_time(event_details&.dig('start_time'))}")
  end

  def find_or_create_contact(email, name)
    return if email.blank?

    contact = @account.contacts.from_email(email)
    return contact if contact.present?

    @account.contacts.create(email: email, name: name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Calendly: Failed to create contact: #{e.message}")
    nil
  end

  def fetch_event_details(event_uri)
    return if event_uri.blank?

    uuid = event_uri.split('/').last
    api_client.get_scheduled_event(uuid)
  rescue StandardError => e
    Rails.logger.error("Calendly: Failed to fetch event details: #{e.message}")
    nil
  end

  def find_conversation_for_contact(contact)
    @account.conversations
            .where(contact_id: contact.id)
            .where.not(status: :resolved)
            .order(last_activity_at: :desc)
            .first
  end

  def build_booking_message(event_details, is_reschedule)
    event_name = event_details['name'] || 'Meeting'
    start_time = format_time(event_details['start_time'])

    is_reschedule ? "Meeting rescheduled: #{event_name} — #{start_time}" : "Meeting booked: #{event_name} — #{start_time}"
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
