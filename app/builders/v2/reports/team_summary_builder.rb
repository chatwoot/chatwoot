class V2::Reports::TeamSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time

  def load_data
    @conversations_count = fetch_conversations_count
    @resolved_count = fetch_resolved_count
    @avg_resolution_time = fetch_average_time('conversation_resolved')
    @avg_first_response_time = fetch_average_time('first_response')
    @avg_reply_time = fetch_average_time('reply_time')
  end

  def fetch_conversations_count
    account.conversations.where(created_at: range).group(:team_id).count
  end

  def fetch_resolved_count
    reporting_events.where(name: 'conversation_resolved').group(group_by_key).count
  end

  def fetch_average_time(event_name)
    get_grouped_average(reporting_events.where(name: event_name))
  end

  def reporting_events
    @reporting_events ||= account.reporting_events.where(created_at: range).joins(:conversation)
  end

  def prepare_report
    account.teams.map do |team|
      build_team_stats(team)
    end
  end

  def build_team_stats(team)
    {
      id: team.id,
      conversations_count: conversations_count[team.id] || 0,
      resolved_conversations_count: resolved_count[team.id] || 0,
      avg_resolution_time: avg_resolution_time[team.id],
      avg_first_response_time: avg_first_response_time[team.id],
      avg_reply_time: avg_reply_time[team.id]
    }
  end

  def group_by_key
    'conversations.team_id'
  end
end
