module Integrations::Calendly::WebhookProcessorService::AppointmentTracker
  private

  def update_appointment_as_scheduled(conversation, event_details)
    appointment = find_pending_appointment(conversation)
    return if appointment.blank?

    event_uuid = extract_event_uuid(event_details)
    appointment.mark_as_scheduled!(
      start_time: event_details['start_time'],
      end_time: event_details['end_time'],
      event_id: event_uuid,
      event_uri: event_details['uri'],
      invitee: build_invitee_snapshot,
      event: build_event_snapshot(event_details)
    )
  rescue StandardError => e
    Rails.logger.error("Calendly: Failed to update appointment as scheduled: #{e.message}")
  end

  def update_appointment_as_cancelled(conversation, event_details)
    appointment = find_appointment_for_cancellation(conversation, event_details)
    return if appointment.blank?

    cancellation = @payload['cancellation'] || {}
    appointment.mark_as_cancelled!(
      canceler_type: cancellation['canceler_type'],
      reason: cancellation['reason'],
      canceled_by: cancellation['canceled_by']
    )
  rescue StandardError => e
    Rails.logger.error("Calendly: Failed to update appointment as cancelled: #{e.message}")
  end

  def build_invitee_snapshot
    @payload.slice(
      'uri', 'name', 'email', 'status', 'timezone',
      'cancel_url', 'reschedule_url', 'rescheduled',
      'created_at', 'updated_at', 'scheduling_method',
      'text_reminder_number', 'first_name', 'last_name',
      'no_show', 'payment'
    ).merge('questions_and_answers' => @payload['questions_and_answers'])
  end

  def build_event_snapshot(event_details)
    event_details.slice(
      'uri', 'name', 'status', 'start_time', 'end_time',
      'event_type', 'location', 'created_at', 'updated_at',
      'event_guests', 'invitees_counter', 'event_memberships',
      'meeting_notes_html', 'meeting_notes_plain'
    )
  end

  def find_appointment_for_cancellation(conversation, event_details)
    event_uuid = extract_event_uuid(event_details)
    appointment = Appointment.find_by(external_event_id: event_uuid) if event_uuid.present?
    appointment || find_pending_appointment(conversation)
  end

  def extract_event_uuid(event_details)
    event_details&.dig('uri')&.split('/')&.last
  end

  def find_pending_appointment(conversation)
    @account.appointments
            .where(conversation: conversation, provider: 'calendly')
            .where(status: [:initiated, :pending])
            .order(created_at: :desc)
            .first
  end
end
