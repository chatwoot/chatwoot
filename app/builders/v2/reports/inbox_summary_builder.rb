class V2::Reports::InboxSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time

  def fetch_conversations_count
    filtered_conversations.group(:inbox_id).count
  end

  def load_reporting_events_data
    results = filtered_reporting_events
              .select(*inbox_reporting_events_select_fields)
              .group('reporting_events.inbox_id')
              .index_by(&:inbox_id)

    @resolved_count = results.transform_values(&:resolved_count)
    @avg_resolution_time = results.transform_values(&:avg_resolution_time)
    @avg_first_response_time = results.transform_values(&:avg_first_response_time)
    @avg_reply_time = results.transform_values(&:avg_reply_time)
  end

  def inbox_reporting_events_select_fields
    [
      'reporting_events.inbox_id as inbox_id',
      "COUNT(CASE WHEN reporting_events.name = 'conversation_resolved' THEN 1 END) as resolved_count",
      inbox_avg_resolution_time_sql,
      inbox_avg_first_response_time_sql,
      inbox_avg_reply_time_sql
    ]
  end

  def inbox_avg_resolution_time_sql
    "AVG(CASE WHEN reporting_events.name = 'conversation_resolved' " \
      "THEN reporting_events.#{average_value_key} END) as avg_resolution_time"
  end

  def inbox_avg_first_response_time_sql
    "AVG(CASE WHEN reporting_events.name = 'first_response' " \
      "THEN reporting_events.#{average_value_key} END) as avg_first_response_time"
  end

  def inbox_avg_reply_time_sql
    "AVG(CASE WHEN reporting_events.name = 'reply_time' " \
      "THEN reporting_events.#{average_value_key} END) as avg_reply_time"
  end

  def prepare_report
    scope = filter_inbox_scope

    scope.map do |inbox|
      build_inbox_stats(inbox)
    end
  end

  def filter_inbox_scope
    scope = account.inboxes

    if params[:inbox_ids].present? && params[:inbox_ids].reject(&:blank?).any?
      scope.where(id: params[:inbox_ids].reject(&:blank?))
    elsif cross_filters?(:inbox_ids)
      apply_cross_filter_scope(scope)
    else
      scope
    end
  end

  def apply_cross_filter_scope(scope)
    all_inbox_ids = collect_all_inbox_ids
    return [] if all_inbox_ids.empty?

    scope.where(id: all_inbox_ids)
  end

  def collect_all_inbox_ids
    [conversations_count.keys, resolved_count.keys, avg_resolution_time.keys, avg_first_response_time.keys, avg_reply_time.keys].flatten.compact.uniq
  end

  def build_inbox_stats(inbox)
    {
      id: inbox.id,
      conversations_count: conversations_count[inbox.id] || 0,
      resolved_conversations_count: resolved_count[inbox.id] || 0,
      avg_resolution_time: avg_resolution_time[inbox.id],
      avg_first_response_time: avg_first_response_time[inbox.id],
      avg_reply_time: avg_reply_time[inbox.id]
    }
  end

  def group_by_key
    :inbox_id
  end

  def average_value_key
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]) ? :value_in_business_hours : :value
  end
end
