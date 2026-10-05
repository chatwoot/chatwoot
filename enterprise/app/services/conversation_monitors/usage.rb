class ConversationMonitors::Usage
  def initialize(account_id)
    @account_id = account_id
  end

  def reserve!
    return unless reserve_credit!

    ConversationMonitors::Monitor.visible.where(account_id: @account_id).pluck(:id).each do |monitor_id|
      ConversationMonitors::BroadcastJob.schedule(monitor_id)
    end
  end

  def snapshot(now = Time.current.utc)
    ConversationMonitors::DailyUsage.monthly_snapshot(@account_id, now)
  end

  private

  def reserve_credit!
    # Serialize the monthly sum and daily increment across all of an account's workers.
    # The credit commits before the provider call, which runs outside this lock.
    Account.find(@account_id).with_lock do
      now = Time.current.utc
      usage = snapshot(now)
      raise CustomExceptions::MonitorEvaluationError.new('monthly_limit', retry_after: (usage[:resets_at] - now.to_f).ceil) if usage[:limit_reached]

      if usage[:daily].last[:calls] >= ConversationMonitors::Configuration::DAILY_CALL_LIMIT
        raise CustomExceptions::MonitorEvaluationError.new('budget_limit', retry_after: (now.tomorrow.beginning_of_day - now).ceil)
      end

      limit_reached = usage[:remaining] == 1
      ConversationMonitors::DailyUsage.record_call!(@account_id, at: now, limit_reached: limit_reached)
      log_reached_limits(usage, now)
      limit_reached
    end
  end

  def log_reached_limits(usage, now)
    log_limit_reached('daily', used: usage[:daily].last[:calls] + 1,
                               limit: ConversationMonitors::Configuration::DAILY_CALL_LIMIT, resets_at: now.tomorrow.beginning_of_day.to_i)
    log_limit_reached('monthly', used: usage[:used] + 1, limit: usage[:limit], resets_at: usage[:resets_at])
  end

  def log_limit_reached(period, used:, limit:, resets_at:)
    return unless used == limit

    ActiveRecord.after_all_transactions_commit do
      Rails.logger.info({
        event: 'conversation_monitor_limit_reached', account_id: @account_id,
        period: period, used: used, limit: limit, resets_at: resets_at
      }.to_json)
    end
  end
end
