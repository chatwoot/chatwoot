class Whatsapp::ConnectionAttemptTracker
  MAX_ATTEMPTS = 5
  WINDOW = 1.hour
  COOLDOWN_MULTIPLIER = 2

  attr_reader :account_id, :waba_id

  def initialize(account_id, waba_id)
    @account_id = account_id
    @waba_id = waba_id
  end

  def can_attempt?
    return false if in_cooldown?

    current_attempts < MAX_ATTEMPTS
  end

  def record_attempt!(success: false)
    Redis::Alfred.multi do |r|
      r.incr(attempts_key)
      r.expire(attempts_key, WINDOW.to_i)
    end

    if success
      clear_failures!
    else
      record_failure!
    end
  end

  def current_attempts
    Redis::Alfred.get(attempts_key).to_i
  end

  def attempts_remaining
    [MAX_ATTEMPTS - current_attempts, 0].max
  end

  def time_until_reset
    ttl = Redis::Alfred.ttl(attempts_key)
    ttl.positive? ? ttl : 0
  end

  def status
    {
      can_attempt: can_attempt?,
      attempts_remaining: attempts_remaining,
      time_until_reset: time_until_reset,
      in_cooldown: in_cooldown?,
      cooldown_remaining: cooldown_remaining
    }
  end

  def in_cooldown?
    Redis::Alfred.exists?(failure_key) && consecutive_failures >= 3
  end

  def cooldown_remaining
    return 0 unless in_cooldown?

    Redis::Alfred.ttl(failure_key)
  end

  def consecutive_failures
    Redis::Alfred.get(failure_key).to_i
  end

  private

  def attempts_key
    @attempts_key ||= "whatsapp:connection_attempts:#{account_id}:#{waba_id}"
  end

  def failure_key
    @failure_key ||= "whatsapp:connection_failures:#{account_id}:#{waba_id}"
  end

  def record_failure!
    failures = Redis::Alfred.incr(failure_key)
    cooldown = calculate_cooldown(failures)
    Redis::Alfred.expire(failure_key, cooldown)
  end

  def clear_failures!
    Redis::Alfred.del(failure_key)
  end

  def calculate_cooldown(failures)
    base_cooldown = 5.minutes.to_i
    # Cap the cooldown at 1 hour
    [base_cooldown * (COOLDOWN_MULTIPLIER**[failures - 1, 0].max), 1.hour.to_i].min
  end
end
