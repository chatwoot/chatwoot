class V2::Reports::InboxSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time, :csat_satisfaction_score

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
    [conversations_count.keys, resolved_count.keys, avg_resolution_time.keys, avg_first_response_time.keys, avg_reply_time.keys, csat_satisfaction_score.keys].flatten.compact.uniq
  end

  def build_inbox_stats(inbox)
    {
      id: inbox.id,
      conversations_count: conversations_count[inbox.id] || 0,
      resolved_conversations_count: resolved_count[inbox.id] || 0,
      avg_resolution_time: avg_resolution_time[inbox.id],
      avg_first_response_time: avg_first_response_time[inbox.id],
      avg_reply_time: avg_reply_time[inbox.id],
      csat_satisfaction_score: csat_satisfaction_score[inbox.id] || 0
    }
  end

  def apply_csat_filters(scope)
    scope = scope.joins(:conversation)
    scope = scope.where(conversations: { inbox_id: params[:inbox_ids].reject(&:blank?) }) if params[:inbox_ids].present?
    scope = scope.where(conversations: { assignee_id: params[:user_ids].reject(&:blank?) }) if params[:user_ids].present?
    scope = scope.where(conversations: { team_id: params[:team_ids].reject(&:blank?) }) if params[:team_ids].present?
    
    if params[:label_ids].present?
      tag_ids = ReportingEvent.tag_ids_for_labels(params[:label_ids].reject(&:blank?), account.id)
      scope = scope.joins('INNER JOIN taggings ON taggings.taggable_id = conversations.id AND taggings.taggable_type = \'Conversation\' AND taggings.context = \'labels\'')
                   .where(taggings: { tag_id: tag_ids }) unless tag_ids.empty?
    end
    
    scope
  end

  def csat_group_by_key
    'conversations.inbox_id'
  end

  def group_by_key
    :inbox_id
  end

  def average_value_key
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]) ? :value_in_business_hours : :value
  end
end
