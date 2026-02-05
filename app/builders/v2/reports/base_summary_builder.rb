class V2::Reports::BaseSummaryBuilder
  include DateRangeHelper

  def build
    load_data
    prepare_report
  end

  private

  def load_data
    @conversations_count = fetch_conversations_count
    @agent_chat_duration = respond_to?(:fetch_agent_chat_duration) ? fetch_agent_chat_duration : nil
    load_reporting_events_data
  end

  def load_reporting_events_data
    index_key = group_by_key.to_s.split('.').last

    results = filtered_reporting_events
              .select(
                "#{group_by_key} as #{index_key}",
                "COUNT(CASE WHEN name = 'conversation_resolved' THEN 1 END) as resolved_count",
                "AVG(CASE WHEN name = 'conversation_resolved' THEN #{average_value_key} END) as avg_resolution_time",
                "AVG(CASE WHEN name = 'first_response' THEN #{average_value_key} END) as avg_first_response_time",
                "AVG(CASE WHEN name = 'reply_time' THEN #{average_value_key} END) as avg_reply_time"
              )
              .group(group_by_key)
              .index_by { |record| record.public_send(index_key) }

    @resolved_count = results.transform_values(&:resolved_count)
    @avg_resolution_time = results.transform_values(&:avg_resolution_time)
    @avg_first_response_time = results.transform_values(&:avg_first_response_time)
    @avg_reply_time = results.transform_values(&:avg_reply_time)
  end

  def reporting_events
    @reporting_events ||= account.reporting_events.where(created_at: range)
  end

  def filtered_reporting_events
    scope = reporting_events
    scope = scope.filter_by_user_id(params[:user_ids]&.reject(&:blank?)) if params[:user_ids].present?
    scope = scope.filter_by_inbox_id(params[:inbox_ids]&.reject(&:blank?)) if params[:inbox_ids].present?
    scope = filter_by_team(scope) if params[:team_ids].present?
    scope
  end

  def filtered_conversations
    scope = account.conversations.where(created_at: range)
    scope = scope.where(assignee_id: params[:user_ids]&.reject(&:blank?)) if params[:user_ids].present?
    scope = scope.where(inbox_id: params[:inbox_ids]&.reject(&:blank?)) if params[:inbox_ids].present?
    scope = scope.where(team_id: params[:team_ids]&.reject(&:blank?)) if params[:team_ids].present?
    scope
  end

  def filter_by_team(scope)
    scope.joins(:conversation).where(conversations: { team_id: params[:team_ids]&.reject(&:blank?) })
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
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]).present? ? :value_in_business_hours : :value
  end
end
