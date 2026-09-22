class ConversationMonitors::Usage
  def initialize(account_id)
    @account_id = account_id
  end

  def reserve!(bytes)
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

  def reconcile!(reserved, used)
    Redis::Alfred.with { |redis| redis.incrby("conversation_monitors:#{daily_key}", used - reserved) }
  end

  private

  def reservations(bytes)
    minute = Time.current.utc.strftime('%Y%m%d%H%M')
    {
      "conversation_monitors:requests:#{minute}" => [1, Integer(ENV.fetch('TYPESAFE_REQUESTS_PER_MINUTE', 600)), 2.minutes.to_i],
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
    @daily_key ||= "account:#{@account_id}:tokens:#{Time.current.utc.strftime('%Y%m%d')}"
  end
end
