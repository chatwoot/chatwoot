# Keeps a WhatsApp number's call hours at Meta in step with the inbox's business hours while
# business_hours_calls_enabled is on. WhatsApp then turns away calls outside those hours itself and
# shows the caller when to call next; Chatwoot's own out-of-hours decline stays as the fallback.
# A plain module (no ActiveSupport::Concern) so it can be included into a prepended Enterprise module.
module Concerns::WhatsappCallHours
  # Meta's weekday names, indexed by WorkingHour#day_of_week (0 is Sunday)
  META_DAYS = %w[SUNDAY MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY].freeze

  def apply_call_hours?
    business_hours_calls_enabled? && inbox.working_hours_enabled?
  end

  # The call hours Meta should hold, without holidays, which the sync reads back from Meta. Meta
  # needs the timezone and weekly hours even to turn call hours off.
  def desired_call_hours
    {
      'status' => apply_call_hours? ? 'ENABLED' : 'DISABLED',
      'timezone_id' => inbox.timezone,
      'weekly_operating_hours' => weekly_operating_hours
    }
  end

  # Queues a sync when Meta may hold something other than the inbox's current hours. A number
  # Chatwoot never sent call hours to is left alone until they're applied, and turning them on waits
  # while calling is off; turning them off never waits. `force` resends a synced schedule.
  def schedule_call_hours_sync(force: false)
    return unless voice_calling_supported?
    return forget_call_hours_sync if call_hours_last_payload.blank? && !apply_call_hours?
    return unless call_hours_sync_wanted?(force)

    update_call_hours_sync_state(call_hours_sync_status: 'pending', call_hours_sync_error: nil)
    Whatsapp::SyncCallHoursJob.perform_later(self)
  end

  def record_call_hours_synced(payload)
    update_call_hours_sync_state(
      call_hours_sync_status: 'synced', call_hours_sync_error: nil,
      call_hours_synced_at: Time.current, call_hours_last_payload: payload
    )
  end

  def record_call_hours_sync_failed(message)
    update_call_hours_sync_state(call_hours_sync_status: 'failed', call_hours_sync_error: message)
  end

  private

  def call_hours_sync_wanted?(force)
    return false if apply_call_hours? && !voice_enabled?

    force || call_hours_sync_status != 'synced' || !call_hours_match?(call_hours_last_payload)
  end

  # Hours edited while call hours are off don't need sending, as Meta doesn't use them until they're on
  def call_hours_match?(payload)
    desired = desired_call_hours
    return payload['status'] == 'DISABLED' if desired['status'] == 'DISABLED'

    payload.slice(*desired.keys) == desired
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

  # Nothing was ever sent to Meta, so a status left from an earlier attempt no longer applies
  def forget_call_hours_sync
    return if call_hours_sync_status.nil?

    update_call_hours_sync_state(call_hours_sync_status: nil, call_hours_sync_error: nil)
  end

  # Saved with validate: false, like the calling toggles, so the remote credential check can't
  # reject a status write; the inbox cache is bumped so the settings page sees the new status.
  def update_call_hours_sync_state(attributes)
    assign_attributes(attributes)
    save!(validate: false)
    inbox.update_account_cache
  end
end
