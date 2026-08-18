class Integrations::GoogleCalendar::BookingLock
  # ponytail: one mutex per Google calendar for the length of a create/update.
  # Ceiling: non-overlapping bookings on the same calendar wait on each other.
  # Upgrade: lock rounded interval keys instead of the whole calendar.
  TTL = 20

  def initialize(account_id:, calendar_id:)
    @key = format(Redis::RedisKeys::CALENDAR_BOOKING_LOCK, account_id: account_id, calendar_id: calendar_id)
    @token = SecureRandom.uuid
    @acquired = false
  end

  def acquire
    @acquired = Redis::Alfred.set(@key, @token, nx: true, ex: TTL)
    @acquired
  end

  def release
    return unless @acquired

    Redis::Alfred.delete_if_equals(@key, @token)
    @acquired = false
  end
end
