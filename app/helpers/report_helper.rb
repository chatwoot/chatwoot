module ReportHelper
  private

  def scope
    case params[:type]
    when :account
      account
    when :inbox
      inbox
    when :agent
      user
    when :label
      label
    when :team
      team
    end
  end

  def get_reporting_events(event_name)
    scope.reporting_events.where(name: event_name, account_id: account.id, created_at: range)
  end

  def get_reporting_events_avg(event_name)
    reporting_events = get_grouped_values(get_reporting_events(event_name))
    if params[:business_hours].present?
      reporting_events.average(:value_in_business_hours) || 0
    else
      reporting_events.average(:value) || 0
    end
  end

  def get_count_metrics(metric)
    case metric
    when 'avg_first_response_time'
      get_grouped_values(get_reporting_events('first_response')).count
    when 'reply_time'
      get_grouped_values(get_reporting_events('reply_time')).count
    when 'avg_resolution_time'
      get_grouped_values(get_reporting_events('conversation_resolved')).count
    else
      {}
    end
  end

  def get_raw_metrics(metric)
    case metric
    when 'avg_first_response_time'
      get_reporting_events_avg('first_response')
    when 'reply_time'
      get_reporting_events_avg('reply_time')
    when 'avg_resolution_time'
      get_reporting_events_avg('conversation_resolved')
    when 'conversations_count'
      get_grouped_values(conversations).count
    when 'incoming_messages_count'
      get_grouped_values(incoming_messages).count
    when 'outgoing_messages_count'
      get_grouped_values(outgoing_messages).count
    when 'resolutions_count'
      get_grouped_values(resolutions).count
    end
  end

  def conversations
    scope.conversations.where(account_id: account.id, created_at: range)
  end

  def incoming_messages
    scope.messages.where(account_id: account.id, created_at: range).incoming.unscope(:order)
  end

  def outgoing_messages
    scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
  end

  def resolutions
    scope.reporting_events.joins(:conversation).select(:conversation_id)
         .where(account_id: account.id, name: :conversation_resolved, conversations: { status: :resolved }, created_at: range)
         .distinct
  end
end
