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

  def conversations_count
    (get_grouped_values scope.conversations).count
  end

  def incoming_messages_count
    (get_grouped_values scope.messages.incoming.unscope(:order)).count
  end

  def outgoing_messages_count
    (get_grouped_values scope.messages.outgoing.unscope(:order)).count
  end

  def resolutions_count
    (get_grouped_values scope.conversations.resolved).count
  end

  def avg_first_response_time
    grouped_reporting_events = (get_grouped_values scope.reporting_events.where(name: 'first_response'))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time
    grouped_reporting_events = (get_grouped_values scope.reporting_events.where(name: 'conversation_resolved'))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time_summary
    reporting_events = scope.reporting_events
                            .where(name: 'conversation_resolved', created_at: range)
    avg_rt = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if avg_rt.blank?

    avg_rt
  end

  def avg_first_response_time_summary
    reporting_events = scope.reporting_events
                            .where(name: 'first_response', created_at: range)
    avg_frt = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if avg_frt.blank?

    avg_frt
  end
end
