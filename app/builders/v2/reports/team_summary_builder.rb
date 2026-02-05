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

  def reporting_events
    @reporting_events ||= account.reporting_events.where(created_at: range).joins(:conversation)
  end

  def load_reporting_events_data
    results = filtered_reporting_events
              .select(*team_reporting_events_select_fields)
              .group('conversations.team_id')
              .index_by(&:team_id)

    @resolved_count = results.transform_values(&:resolved_count)
    @avg_resolution_time = results.transform_values(&:avg_resolution_time)
    @avg_first_response_time = results.transform_values(&:avg_first_response_time)
    @avg_reply_time = results.transform_values(&:avg_reply_time)
  end

  def team_reporting_events_select_fields
    [
      'conversations.team_id as team_id',
      "COUNT(CASE WHEN reporting_events.name = 'conversation_resolved' THEN 1 END) as resolved_count",
      team_avg_resolution_time_sql,
      team_avg_first_response_time_sql,
      team_avg_reply_time_sql
    ]
  end

  def team_avg_resolution_time_sql
    "AVG(CASE WHEN reporting_events.name = 'conversation_resolved' " \
      "THEN reporting_events.#{average_value_key} END) as avg_resolution_time"
  end

  def team_avg_first_response_time_sql
    "AVG(CASE WHEN reporting_events.name = 'first_response' " \
      "THEN reporting_events.#{average_value_key} END) as avg_first_response_time"
  end

  def team_avg_reply_time_sql
    "AVG(CASE WHEN reporting_events.name = 'reply_time' " \
      "THEN reporting_events.#{average_value_key} END) as avg_reply_time"
  end

  def filtered_reporting_events
    scope = reporting_events
    scope = apply_team_reporting_user_filter(scope)
    scope = apply_team_reporting_inbox_filter(scope)
    scope = apply_team_reporting_team_filter(scope)
    apply_team_reporting_label_filter(scope)
  end

  def apply_team_reporting_user_filter(scope)
    return scope if params[:user_ids].blank?

    scope.filter_by_user_id(params[:user_ids]&.reject(&:blank?))
  end

  def apply_team_reporting_inbox_filter(scope)
    return scope if params[:inbox_ids].blank?

    scope.filter_by_inbox_id(params[:inbox_ids]&.reject(&:blank?))
  end

  def apply_team_reporting_team_filter(scope)
    return scope if params[:team_ids].blank?

    scope.where(conversations: { team_id: params[:team_ids]&.reject(&:blank?) })
  end

  def apply_team_reporting_label_filter(scope)
    return scope if params[:label_ids].blank?

    scope.filter_by_label_ids(params[:label_ids], account.id)
  end

  def prepare_report
    scope = filter_team_scope

    scope.map do |team|
      build_team_stats(team)
    end
  end

  def filter_team_scope
    scope = account.teams

    if params[:team_ids].present? && params[:team_ids].reject(&:blank?).any?
      scope.where(id: params[:team_ids].reject(&:blank?))
    elsif cross_team_filters?
      apply_team_cross_filter_scope(scope)
    else
      scope
    end
  end

  def cross_team_filters?
    params[:user_ids].present? || params[:inbox_ids].present? || params[:label_ids].present?
  end

  def apply_team_cross_filter_scope(scope)
    all_team_ids = collect_all_team_ids
    return [] if all_team_ids.empty?

    scope.where(id: all_team_ids)
  end

  def collect_all_team_ids
    [
      conversations_count.keys,
      resolved_count.keys,
      avg_resolution_time.keys,
      avg_first_response_time.keys,
      avg_reply_time.keys
    ].flatten.compact.uniq
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
