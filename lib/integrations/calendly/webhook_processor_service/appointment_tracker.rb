module Integrations::Calendly::WebhookProcessorService::AppointmentTracker
  private

  def update_appointment_as_scheduled(conversation, event_details)
    event_uri = event_details['uri']
    event_uuid = event_uri&.split('/')&.last
    appointment = find_pending_appointment(conversation)
    return if appointment.blank?

    appointment.mark_as_scheduled!(
      start_time: event_details['start_time'],
      event_id: event_uuid,
      invitee: @payload.slice('name', 'email', 'uri', 'cancel_url', 'reschedule_url'),
      event_uri: event_uri
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
