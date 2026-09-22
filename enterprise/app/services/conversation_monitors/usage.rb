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
      record_call(now, usage[:used] + 1 == usage[:limit])
    end
    return unless reached_limit

    ConversationMonitors::Monitor.visible.where(account_id: @account_id).pluck(:id).each do |monitor_id|
      ConversationMonitors::BroadcastJob.schedule(monitor_id)
    end
  end

  def snapshot(now = Time.current.utc)
    first_day = now.to_date.beginning_of_month
    resets_at = now.beginning_of_month.next_month
    records = daily_usages.where(usage_date: first_day...resets_at.to_date).order(:usage_date).pluck(:usage_date, :calls_count, :limit_reached_at)
    used = records.sum { |(_, count, _)| count }
    limit = ConversationMonitors::Configuration::MONTHLY_CALL_LIMIT
    counts = records.to_h { |date, count, _| [date, count] }
    {
      limit: limit, used: used, remaining: [limit - used, 0].max, limit_reached: used >= limit,
      limit_reached_at: records.filter_map(&:last).min&.to_i, resets_at: resets_at.to_i,
      period_start: first_day.iso8601, timezone: 'UTC',
      daily: (first_day..now.to_date).map { |date| { date: date.iso8601, calls: counts.fetch(date, 0) } }
    }
  end

  def reconcile!(reserved, used)
    Redis::Alfred.with { |redis| redis.incrby("conversation_monitors:#{daily_key}", used - reserved) }
  end

  private

  def record_call(now, reached_limit)
    daily = daily_usages.find_or_initialize_by(usage_date: @usage_date)
    daily.calls_count += 1
    daily.limit_reached_at = now if reached_limit
    daily.save!
    reached_limit
  end

  def daily_usages
    ConversationMonitors::DailyUsage.where(account_id: @account_id)
  end

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
