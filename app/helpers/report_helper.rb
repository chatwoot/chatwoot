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
    (get_grouped_values scope.reporting_events.where(name: 'first_response')).average(:value)
  end

  def avg_resolution_time
    (get_grouped_values scope.reporting_events.where(name: 'conversation_resolved')).average(:value)
  end

  def avg_resolution_time_summary
    avg_rt = scope.reporting_events
                  .where(name: 'conversation_resolved', created_at: range)
                  .average(:value)

    return 0 if avg_rt.blank?

    avg_rt
  end

  def avg_first_response_time_summary
    avg_frt = scope.reporting_events
                   .where(name: 'first_response', created_at: range)
                   .average(:value)

    return 0 if avg_frt.blank?

    avg_frt
  end
end
