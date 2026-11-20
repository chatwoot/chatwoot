module Concerns::WhatsappCallHours
  META_DAYS = %w[SUNDAY MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY].freeze

  def apply_call_hours?
    business_hours_calls_enabled? && inbox.working_hours_enabled?
  end

  def apply_call_hours!
    if apply_call_hours? && weekly_operating_hours.empty?
      errors.add(:base, I18n.t('inbox.call_hours.closed_every_day'))
      raise ActiveRecord::RecordInvalid, self
    end

    send_call_hours
  end

  def call_hours_match_whatsapp?
    current = provider_service.calling_settings.dig('calling', 'call_hours') || {}
    desired = desired_call_hours
    return current['status'] != 'ENABLED' if desired['status'] == 'DISABLED'

    current.slice('status', 'timezone_id') == desired.slice('status', 'timezone_id') &&
      sorted_hours(current['weekly_operating_hours']) == sorted_hours(desired['weekly_operating_hours'])
  end

  private

  def send_call_hours
    call_hours = call_hours_for_whatsapp
    provider_service.update_call_hours(call_hours) if call_hours['weekly_operating_hours'].present?
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL HOURS] update failed for channel #{id}: #{e.message}"
    errors.add(:base, I18n.t('inbox.call_hours.whatsapp_failed', error: e.message))
    raise ActiveRecord::RecordInvalid, self
  end

  def desired_call_hours
    {
      'status' => apply_call_hours? ? 'ENABLED' : 'DISABLED',
      'timezone_id' => inbox.timezone,
      'weekly_operating_hours' => weekly_operating_hours
    }
  end

  def call_hours_for_whatsapp
    current = provider_service.calling_settings.dig('calling', 'call_hours') || {}
    call_hours = desired_call_hours
    call_hours['holiday_schedule'] = current['holiday_schedule'] unless current['holiday_schedule'].nil?
    call_hours['weekly_operating_hours'] = Array(current['weekly_operating_hours']) if call_hours['weekly_operating_hours'].empty?
    call_hours
  end

  def sorted_hours(hours)
    Array(hours).map { |day| day.slice('day_of_week', 'open_time', 'close_time') }
                .sort_by { |day| [META_DAYS.index(day['day_of_week']), day['open_time']] }
  end

  def weekly_operating_hours
    inbox.working_hours.order(:day_of_week).reject(&:closed_all_day?).map do |working_hour|
      {
        'day_of_week' => META_DAYS[working_hour.day_of_week],
        'open_time' => meta_time(working_hour.open_hour, working_hour.open_minutes),
        'close_time' => meta_time(working_hour.close_hour, working_hour.close_minutes)
      }
    end
  end

  def meta_time(hour, minutes)
    format('%<hour>02d%<minutes>02d', hour: hour, minutes: minutes)
  end
end
