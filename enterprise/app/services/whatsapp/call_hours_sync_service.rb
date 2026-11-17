# Sends an inbox's business hours to Meta as the WhatsApp number's call hours. Meta replaces the
# whole call_hours object and clears any holidays it isn't sent, so the holidays Meta holds are read
# first and sent back. Records the outcome on the channel for the settings page.
class Whatsapp::CallHoursSyncService
  pattr_initialize [:channel!]

  def perform
    payload = channel.desired_call_hours
    holidays = current_holidays
    payload = payload.merge('holiday_schedule' => holidays) unless holidays.nil?

    channel.provider_service.update_call_hours(payload)
    channel.record_call_hours_synced(payload)
    # Settings saved while Meta was being updated are sent next
    channel.schedule_call_hours_sync
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL HOURS] sync failed for channel #{channel.id}: #{e.message}"
    channel.record_call_hours_sync_failed(e.message)
  end

  private

  # Meta leaves call hours out of its reply while they're off, so the holidays last sent stand in.
  # An empty list from Meta is kept as it is.
  def current_holidays
    call_hours = channel.provider_service.calling_settings.dig('calling', 'call_hours') || {}
    return call_hours['holiday_schedule'] if call_hours.key?('holiday_schedule')

    channel.call_hours_last_payload&.dig('holiday_schedule')
  end
end
