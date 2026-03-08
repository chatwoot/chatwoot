class Integrations::Calendly::WebhookProcessorService
  include Integrations::Calendly::WebhookProcessorService::AppointmentTracker
  include Integrations::Calendly::WebhookProcessorService::NotificationHandler

  E164_REGEX = /\A\+[1-9]\d{1,14}\z/

  def initialize(hook:, event:, payload:, webhook_log: nil)
    @hook = hook
    @event = event
    @payload = payload
    @account = hook.account
    @webhook_log = webhook_log
  end

  def perform
    @webhook_log&.mark_processing!
    process_event
    @webhook_log&.mark_processed!
  rescue StandardError => e
    @webhook_log&.mark_failed!(e.message)
    raise
  end

  private

  def process_event
    case @event
    when 'invitee.created' then handle_invitee_created
    when 'invitee.canceled' then handle_invitee_canceled
    end
  end

  def handle_invitee_created
    contact = find_or_create_contact(@payload['email'], @payload['name'])
    return if contact.blank?

    event_details = resolve_event_details
    return if event_details.blank?

    is_reschedule = @payload['old_invitee'].present? || @payload['rescheduled'] == true
    conversation = find_or_create_conversation_for_contact(contact)
    return if conversation.blank?

    update_appointment_as_scheduled(conversation, event_details)

    activity_text = build_booking_message(event_details, is_reschedule)
    message = create_activity_message(conversation, activity_text)
    return if message.nil?

    event_type = is_reschedule ? 'rescheduled' : 'booked'
    send_notification(conversation, event_type, event_details, contact)
  end

  def handle_invitee_canceled
    return if @payload['new_invitee'].present?

    contact = find_contact(@payload['email'])
    return if contact.blank?

    event_details = resolve_event_details
    conversation = find_or_create_conversation_for_contact(contact)
    return if conversation.blank?

    update_appointment_as_cancelled(conversation, event_details)

    message = create_activity_message(conversation, build_cancellation_message(event_details))
    return if message.nil?

    send_notification(conversation, 'canceled', event_details, contact,
                      cancellation_reason: @payload.dig('cancellation', 'reason'))
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
    existing = @account.conversations.where(contact_id: contact.id).where.not(status: :resolved).order(last_activity_at: :desc).first
    return existing if existing.present?

    contact_inbox = contact.contact_inboxes.joins(:conversations)
                           .order('conversations.last_activity_at DESC').first || contact.contact_inboxes.last
    return if contact_inbox.blank?

    ::Conversation.create!(account_id: @account.id, inbox_id: contact_inbox.inbox_id,
                           contact_id: contact.id, contact_inbox_id: contact_inbox.id)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Calendly: Failed to create conversation: #{e.message}")
    nil
  end

  def resolve_event_details
    @payload['scheduled_event'] || fetch_event_details(@payload['event'])
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

  def build_cancellation_message(event_details)
    "Meeting canceled: #{event_details&.dig('name') || 'Meeting'} — #{format_time(event_details&.dig('start_time'))}"
  end

  def create_activity_message(conversation, content)
    return nil if conversation.messages.exists?(message_type: :activity, content: content)

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
