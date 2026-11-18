class Whatsapp::CallHoursSyncService
  pattr_initialize [:channel!]

  def perform
    @attempted = channel.desired_call_hours
    payload = with_current_holidays(@attempted)
    channel.provider_service.update_call_hours(payload)
    channel.reload.record_call_hours_synced(payload)
    channel.schedule_call_hours_sync
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL HOURS] sync failed for channel #{channel.id}: #{e.message}"
    record_failure(e.message)
  end

  private

  def with_current_holidays(call_hours)
    holidays = current_holidays
    holidays.nil? ? call_hours : call_hours.merge('holiday_schedule' => holidays)
  end

  def current_holidays
    call_hours = channel.provider_service.calling_settings.dig('calling', 'call_hours') || {}
    return call_hours['holiday_schedule'] if call_hours.key?('holiday_schedule')

    channel.call_hours_last_payload&.dig('holiday_schedule')
  end

  def record_failure(message)
    channel.reload.record_call_hours_sync_failed(message)
    return if @attempted.nil? || channel.desired_call_hours == @attempted

    channel.schedule_call_hours_sync(force: true)
  end
end
