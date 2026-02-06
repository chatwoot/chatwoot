class V2::Reports::BaseSummaryBuilder
  include DateRangeHelper

  def build
    load_data
    prepare_report
  end

  private

  def load_data
    @conversations_count = fetch_conversations_count
    @agent_chat_duration = fetch_agent_chat_duration if respond_to?(:fetch_agent_chat_duration, true)
    load_reporting_events_data
    load_csat_data
  end

  def load_reporting_events_data
    index_key = group_by_key.to_s.split('.').last

    results = filtered_reporting_events
              .select(*reporting_events_select_fields)
              .group(group_by_key)
              .index_by { |record| record.public_send(index_key) }

    @resolved_count = results.transform_values(&:resolved_count)
    @avg_resolution_time = results.transform_values(&:avg_resolution_time)
    @avg_first_response_time = results.transform_values(&:avg_first_response_time)
    @avg_reply_time = results.transform_values(&:avg_reply_time)
  end

  def reporting_events_select_fields
    index_key = group_by_key.to_s.split('.').last
    [
      "#{group_by_key} as #{index_key}",
      "COUNT(CASE WHEN reporting_events.name = 'conversation_resolved' THEN 1 END) as resolved_count",
      avg_resolution_time_sql,
      avg_first_response_time_sql,
      avg_reply_time_sql
    ]
  end

  def avg_resolution_time_sql
    "AVG(CASE WHEN reporting_events.name = 'conversation_resolved' " \
      "THEN reporting_events.#{average_value_key} END) as avg_resolution_time"
  end

  def avg_first_response_time_sql
    "AVG(CASE WHEN reporting_events.name = 'first_response' " \
      "THEN reporting_events.#{average_value_key} END) as avg_first_response_time"
  end

  def avg_reply_time_sql
    "AVG(CASE WHEN reporting_events.name = 'reply_time' " \
      "THEN reporting_events.#{average_value_key} END) as avg_reply_time"
  end

  def reporting_events
    @reporting_events ||= account.reporting_events.where(created_at: range)
  end

  def filtered_reporting_events
    apply_filters(reporting_events)
  end

  def filtered_conversations
    apply_conversation_filters(account.conversations.where(created_at: range))
  end

  def apply_filters(scope)
    scope = apply_user_filter(scope)
    scope = apply_inbox_filter(scope)
    scope = apply_label_filter(scope)
    apply_team_filter(scope)
  end

  def apply_user_filter(scope)
    return scope if params[:user_ids].blank?

    scope.filter_by_user_id(params[:user_ids]&.reject(&:blank?))
  end

  def apply_inbox_filter(scope)
    return scope if params[:inbox_ids].blank?

    scope.filter_by_inbox_id(params[:inbox_ids]&.reject(&:blank?))
  end

  def apply_label_filter(scope)
    return scope if params[:label_ids].blank?

    scope.filter_by_label_ids(params[:label_ids], account.id)
  end

  def apply_team_filter(scope)
    return scope if params[:team_ids].blank?

    filter_by_team(scope)
  end

  def apply_conversation_filters(scope)
    scope = apply_conversation_user_filter(scope)
    scope = apply_conversation_inbox_filter(scope)
    scope = apply_conversation_team_filter(scope)
    apply_conversation_label_filter(scope)
  end

  def apply_conversation_user_filter(scope)
    return scope if params[:user_ids].blank?

    scope.where(assignee_id: params[:user_ids]&.reject(&:blank?))
  end

  def apply_conversation_inbox_filter(scope)
    return scope if params[:inbox_ids].blank?

    scope.where(inbox_id: params[:inbox_ids]&.reject(&:blank?))
  end

  def apply_conversation_team_filter(scope)
    return scope if params[:team_ids].blank?

    scope.where(team_id: params[:team_ids]&.reject(&:blank?))
  end

  def apply_conversation_label_filter(scope)
    return scope if params[:label_ids].blank?

    scope.filter_by_label_ids(params[:label_ids], account.id)
  end

  def filter_by_team(scope)
    scope.joins(:conversation).where(conversations: { team_id: params[:team_ids]&.reject(&:blank?) })
  end

  def cross_filters?(exclude_param = nil)
    filter_params = [:user_ids, :inbox_ids, :team_ids, :label_ids] - Array(exclude_param)
    filter_params.any? { |param| params[param].present? && params[param].reject(&:blank?).any? }
  end
  
  def load_csat_data
    @csat_satisfaction_score = fetch_csat_satisfaction_score
  end

  def fetch_csat_satisfaction_score
    scope = filtered_csat_responses
            .select(csat_group_by_field, csat_select_fields)
            .group(csat_group_by_key)

    scope.each_with_object({}) do |record, hash|
      key = record.public_send(csat_group_key_name)
      total = record.total_count.to_f
      positive = record.positive_count.to_f
      
      hash[key] = total > 0 ? ((positive / total) * 100).round(2) : 0
    end
  end

  def filtered_csat_responses
    scope = account.csat_survey_responses.where(created_at: range).where.not(rating: nil)
    apply_csat_filters(scope)
  end

  def apply_csat_filters(scope)
    scope
  end

  def csat_select_fields
    <<-SQL.squish
      COUNT(*) as total_count,
      COUNT(CASE WHEN rating IN (4, 5) THEN 1 END) as positive_count
    SQL
  end  

  def csat_group_by_key
    # Override this method
  end

  def csat_group_by_field
    csat_group_by_key
  end

  def csat_group_key_name
    csat_group_by_key.to_s.split('.').last.to_sym
  end

  def fetch_conversations_count
    # Override this method
  end

  def group_by_key
    # Override this method
  end

  def prepare_report
    # Override this method
  end

  def average_value_key
    use_business_hours? ? :value_in_business_hours : :value
  end

  def use_business_hours?
    ActiveModel::Type::Boolean.new.cast(params[:business_hours])
  end
end
