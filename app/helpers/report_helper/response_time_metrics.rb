module ReportHelper::ResponseTimeMetrics
  private

  def avg_first_response_time
    grouped_reporting_events = get_grouped_values(scope.reporting_events.where(name: 'first_response', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_first_response_time_summary
    reporting_events = scope.reporting_events.where(name: 'first_response', account_id: account.id, created_at: range)
    avg_frt = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if avg_frt.blank?

    avg_frt
  end

  def reply_time
    grouped_reporting_events = get_grouped_values(scope.reporting_events.where(name: 'reply_time', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def reply_time_summary
    reporting_events = scope.reporting_events.where(name: 'reply_time', account_id: account.id, created_at: range)
    reply_time = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if reply_time.blank?

    reply_time
  end

  def avg_resolution_time
    grouped_reporting_events = get_grouped_values(scope.reporting_events.where(name: 'conversation_resolved', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time_summary
    reporting_events = scope.reporting_events.where(name: 'conversation_resolved', account_id: account.id, created_at: range)
    avg_rt = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if avg_rt.blank?

    avg_rt
  end

  def agent_chat_duration
    return 0 unless params[:type].to_sym == :agent

    scope.reporting_events.where(name: :agent_chat_duration, account_id: account.id, created_at: range).average(:value) || 0
  end

  def agent_chat_duration_summary
    return 0 unless params[:type].to_sym == :agent

    reporting_events = scope.reporting_events.where(name: :agent_chat_duration, account_id: account.id, created_at: range)

    reporting_events.average(:value) || 0
  end
end
