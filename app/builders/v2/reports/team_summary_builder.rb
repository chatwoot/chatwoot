class V2::Reports::TeamSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time

  def fetch_conversations_count
    filtered_conversations.group(:team_id).count
  end

  def filtered_conversations
    scope = account.conversations.where(created_at: range)
    scope = scope.where(assignee_id: params[:user_ids]&.reject(&:blank?)) if params[:user_ids].present?
    scope = scope.where(inbox_id: params[:inbox_ids]&.reject(&:blank?)) if params[:inbox_ids].present?
    scope = scope.where(team_id: params[:team_ids]&.reject(&:blank?)) if params[:team_ids].present?
    scope
  end

  def reporting_events
    @reporting_events ||= account.reporting_events.where(created_at: range).joins(:conversation)
  end

  def load_reporting_events_data
    results = filtered_reporting_events
              .select(
                "conversations.team_id as team_id",
                "COUNT(CASE WHEN reporting_events.name = 'conversation_resolved' THEN 1 END) as resolved_count",
                "AVG(CASE WHEN reporting_events.name = 'conversation_resolved' THEN reporting_events.#{average_value_key} END) as avg_resolution_time",
                "AVG(CASE WHEN reporting_events.name = 'first_response' THEN reporting_events.#{average_value_key} END) as avg_first_response_time",
                "AVG(CASE WHEN reporting_events.name = 'reply_time' THEN reporting_events.#{average_value_key} END) as avg_reply_time"
              )
              .group('conversations.team_id')
              .index_by(&:team_id)

    @resolved_count = results.transform_values(&:resolved_count)
    @avg_resolution_time = results.transform_values(&:avg_resolution_time)
    @avg_first_response_time = results.transform_values(&:avg_first_response_time)
    @avg_reply_time = results.transform_values(&:avg_reply_time)
  end

  def filtered_reporting_events
    scope = reporting_events
    scope = scope.filter_by_user_id(params[:user_ids]&.reject(&:blank?)) if params[:user_ids].present?
    scope = scope.filter_by_inbox_id(params[:inbox_ids]&.reject(&:blank?)) if params[:inbox_ids].present?
    scope = scope.where(conversations: { team_id: params[:team_ids]&.reject(&:blank?) }) if params[:team_ids].present?
    scope
  end

  def prepare_report
    scope = account.teams
    
    if params[:team_ids].present? && params[:team_ids].reject(&:blank?).any?
      scope = scope.where(id: params[:team_ids].reject(&:blank?))
    else
      if params[:user_ids].present? || params[:inbox_ids].present?
        all_team_ids = [
          conversations_count.keys,
          resolved_count.keys,
          avg_resolution_time.keys,
          avg_first_response_time.keys,
          avg_reply_time.keys
        ].flatten.compact.uniq

        return [] if all_team_ids.empty?
        scope = scope.where(id: all_team_ids)
      end
    end
    
    scope.map do |team|
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
