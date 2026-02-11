module ReportHelper::BotMetrics
  private

  def bot_resolutions_count
    get_grouped_values(bot_resolutions).count
  end

  def bot_handoffs_count
    get_grouped_values(bot_handoffs).count
  end

  def bot_resolutions
    scope.reporting_events.where(account_id: account.id, name: :conversation_bot_resolved, created_at: range)
  end

  def bot_handoffs
    scope.reporting_events.joins(:conversation)
         .select(:conversation_id)
         .where(account_id: account.id, name: :conversation_bot_handoff, created_at: range)
         .distinct
  end

  def bot_first_response_time
    get_grouped_values(scope.reporting_events.where(name: 'bot_first_response', account_id: account.id))
  end

  def bot_first_response_time_summary
    reporting_events = scope.reporting_events.where(name: 'bot_first_response', account_id: account.id, created_at: range)
    first_response_time = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if first_response_time.blank?

    first_response_time
  end

  def bot_reply_time
    grouped_reporting_events = get_grouped_values(scope.reporting_events.where(name: 'bot_reply_time', account_id: account.id))

    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def bot_reply_time_summary
    reporting_events = scope.reporting_events.where(name: 'bot_reply_time', account_id: account.id, created_at: range)
    reply_time = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if reply_time.blank?

    reply_time
  end
end
