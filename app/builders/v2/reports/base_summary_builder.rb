class V2::Reports::BaseSummaryBuilder
  include DateRangeHelper

  def build
    load_data
    prepare_report
  end

  private

  def load_data
    @conversations_count = fetch_conversations_count
    @resolved_count = fetch_resolved_count
    @avg_resolution_time = fetch_average_time('conversation_resolved')
    @avg_first_response_time = fetch_average_time('first_response')
    @avg_reply_time = fetch_average_time('reply_time')
  end

  def reporting_events
    @reporting_events ||= account.reporting_events.where(created_at: range)
  end

  def fetch_conversations_count
    # Override this method
  end

  def fetch_average_time(event_name)
    get_grouped_average(reporting_events.where(name: event_name))
  end

  def fetch_resolved_count
    reporting_events.where(name: 'conversation_resolved').group(group_by_key).count
  end

  def group_by_key
    # Override this method
  end

  def prepare_report
    # Override this method
  end

  def get_grouped_average(events)
    events.group(group_by_key).average(average_value_key)
  end

  def average_value_key
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]).present? ? :value_in_business_hours : :value
  end
end
