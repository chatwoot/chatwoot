class V2::Reports::TeamSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    set_grouped_conversations_count
    set_grouped_avg_reply_time
    set_grouped_avg_first_response_time
    set_grouped_avg_resolution_time
    prepare_report
  end

  private

  def set_grouped_conversations_count
    @grouped_conversations_count = Current.account.conversations.where(created_at: range).group('team_id').count
  end

  def set_grouped_avg_resolution_time
    @grouped_avg_resolution_time = get_grouped_average(reporting_events.where(name: 'conversation_resolved'))
  end

  def set_grouped_avg_first_response_time
    @grouped_avg_first_response_time = get_grouped_average(reporting_events.where(name: 'first_response'))
  end

  def set_grouped_avg_reply_time
    @grouped_avg_reply_time = get_grouped_average(reporting_events.where(name: 'reply_time'))
  end

  def reporting_events
    @reporting_events ||= Current.account.reporting_events.where(created_at: range).joins(:conversation)
  end

  def group_by_key
    'conversations.team_id'
  end

  def prepare_report
    account.teams.each_with_object([]) do |team, arr|
      arr << {
        id: team.id,
        conversations_count: @grouped_conversations_count[team.id],
        avg_resolution_time: @grouped_avg_resolution_time[team.id],
        avg_first_response_time: @grouped_avg_first_response_time[team.id],
        avg_reply_time: @grouped_avg_reply_time[team.id]
      }
    end
  end
end
