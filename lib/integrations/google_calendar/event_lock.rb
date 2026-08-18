class Integrations::GoogleCalendar::EventLock
  TTL = 180

  def initialize(account_id:, event_id:)
    @key = format(Redis::RedisKeys::CALENDAR_EVENT_LOCK, account_id: account_id, event_id: event_id)
  end

  def acquire(user)
    existing = holder
    if existing && existing['user_id'] == user.id
      Redis::Alfred.setex(@key, serialize(user), TTL)
      return success(existing)
    end
    return failure(existing) if existing

    payload = serialize(user)
    return success(JSON.parse(payload)) if Redis::Alfred.set(@key, payload, nx: true, ex: TTL)

    failure(holder)
  end

  def heartbeat(user)
    existing = holder
    return acquire(user) if existing.blank?
    return failure(existing) unless existing['user_id'] == user.id

    Redis::Alfred.setex(@key, serialize(user), TTL)
    success(existing)
  end

  def release(user)
    existing = holder
    return true if existing.blank?
    return false unless existing['user_id'] == user.id

    Redis::Alfred.delete(@key)
    true
  end

  def holder
    value = Redis::Alfred.get(@key)
    value.present? ? JSON.parse(value) : nil
  end

  private

  def serialize(user)
    { user_id: user.id, name: user.name }.to_json
  end

  def success(holder_data)
    { ok: true, holder: holder_data }
  end

  def failure(holder_data)
    { ok: false, holder: holder_data }
  end
end
