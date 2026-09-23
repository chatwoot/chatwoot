class ConversationMonitors::Usage
  def initialize(account_id)
    @account_id = account_id
  end

  def reserve!(bytes)
    # Serialize the monthly sum and daily increment across all of an account's workers.
    # The credit commits before the provider call, which runs outside this lock.
    reached_limit = Account.find(@account_id).with_lock do
      now = Time.current.utc
      @usage_date = now.to_date
      usage = snapshot(now)
      raise CustomExceptions::MonitorEvaluationError.new('monthly_limit', retry_after: (usage[:resets_at] - now.to_f).ceil) if usage[:limit_reached]

      reserve_capacity!(bytes)
      limit_reached = usage[:used] + 1 == usage[:limit]
      ConversationMonitors::DailyUsage.record_call!(@account_id, at: now, limit_reached: limit_reached)
      limit_reached
    end
    return unless reached_limit

    ConversationMonitors::Monitor.visible.where(account_id: @account_id).pluck(:id).each do |monitor_id|
      ConversationMonitors::BroadcastJob.schedule(monitor_id)
    end
  end

  def snapshot(now = Time.current.utc)
    ConversationMonitors::DailyUsage.monthly_snapshot(@account_id, now)
  end

  def reconcile!(reserved, used)
    Redis::Alfred.with { |redis| redis.incrby("conversation_monitors:#{daily_key}", used - reserved) }
  end

  private

  def reserve_capacity!(bytes)
    counters = reservations(bytes)
    Redis::Alfred.with do |redis|
      loop do
        reserved = redis.watch(*counters.keys) do
          enforce_limits!(redis, counters)
          redis.multi do |transaction|
            counters.each do |key, (amount, _, expiry)|
              transaction.incrby(key, amount)
              transaction.expire(key, expiry)
            end
          end
        end
        break if reserved
      end
    end
  end

  def reservations(bytes)
    minute = Time.current.utc.strftime('%Y%m%d%H%M')
    {
      "conversation_monitors:requests:#{minute}" => [1, Integer(ENV.fetch('CONVERSATION_MONITORS_REQUESTS_PER_MINUTE', 600)), 2.minutes.to_i],
      "conversation_monitors:account:#{@account_id}:requests:#{minute}" => [1, 60, 2.minutes.to_i],
      "conversation_monitors:#{daily_key}" => [bytes, Integer(ENV.fetch('CONVERSATION_MONITORS_DAILY_TOKEN_LIMIT', 20_000_000)), 2.days.to_i]
    }
  end

  def enforce_limits!(redis, counters)
    current = redis.mget(*counters.keys)
    counters.values.each_with_index do |(amount, limit, _), index|
      raise_limit!(index) if current[index].to_i + amount > limit
    end
  end

  def raise_limit!(index)
    code = index == 2 ? 'budget_limit' : 'rate_limit'
    delay = code == 'budget_limit' ? 1.day.from_now.utc.beginning_of_day - Time.current : 60
    raise CustomExceptions::MonitorEvaluationError.new(code, retry_after: delay.ceil)
  end

  def daily_key
    "account:#{@account_id}:tokens:#{(@usage_date || Time.current.utc.to_date).strftime('%Y%m%d')}"
  end
end
