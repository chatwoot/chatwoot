class ConversationMonitors::Usage
  def initialize(account_id)
    @account_id = account_id
  end

  def reserve!(bytes)
    return unless reserve_credit!(bytes)

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

  def reserve_credit!(bytes)
    tokens_reserved = false
    # Serialize the monthly sum and daily increment across all of an account's workers.
    # The credit commits before the provider call, which runs outside this lock.
    Account.find(@account_id).with_lock do
      now = Time.current.utc
      @usage_date = now.to_date
      usage = snapshot(now)
      raise CustomExceptions::MonitorEvaluationError.new('monthly_limit', retry_after: (usage[:resets_at] - now.to_f).ceil) if usage[:limit_reached]

      reserve_tokens!(bytes)
      tokens_reserved = true
      limit_reached = usage[:used] + 1 == usage[:limit]
      ConversationMonitors::DailyUsage.record_call!(@account_id, at: now, limit_reached: limit_reached)
      limit_reached
    end
  rescue StandardError
    reconcile!(bytes, 0) if tokens_reserved
    raise
  end

  def reserve_tokens!(bytes)
    key = "conversation_monitors:#{daily_key}"
    limit = Integer(ENV.fetch('CONVERSATION_MONITORS_DAILY_TOKEN_LIMIT', 20_000_000))
    Redis::Alfred.with do |redis|
      loop do
        reserved = redis.watch(key) do
          if redis.get(key).to_i + bytes > limit
            delay = 1.day.from_now.utc.beginning_of_day - Time.current
            raise CustomExceptions::MonitorEvaluationError.new('budget_limit', retry_after: delay.ceil)
          end
          redis.multi do |transaction|
            transaction.incrby(key, bytes)
            transaction.expire(key, 2.days.to_i)
          end
        end
        break if reserved
      end
    end
  end

  def daily_key
    "account:#{@account_id}:tokens:#{(@usage_date || Time.current.utc.to_date).strftime('%Y%m%d')}"
  end
end
