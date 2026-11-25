class V2::Reports::BaseSummaryBuilder
  include DateRangeHelper

  def build
    load_data
    prepare_report
  end

  private

  def load_data
    results = data_source.summary

    @conversations_count = results.transform_values { |data| data[:conversations_count] }
    @resolved_count = results.transform_values { |data| data[:resolved_conversations_count] }
    @handled_count = results.transform_values { |data| data[:handled_conversations_count] }
    @avg_resolution_time = results.transform_values { |data| data[:avg_resolution_time] }
    @avg_first_response_time = results.transform_values { |data| data[:avg_first_response_time] }
    @avg_reply_time = results.transform_values { |data| data[:avg_reply_time] }
  end

  def group_by_key
    # Override this method
  end

  def prepare_report
    # Override this method
  end

  def data_source
    @data_source ||= Reports::DataSource.for(
      account: account,
      metric: nil,
      dimension_type: summary_dimension_type,
      dimension_id: nil,
      scope: nil,
      range: range,
      group_by: 'day',
      timezone_offset: params[:timezone_offset],
      business_hours: params[:business_hours],
      filters: summary_filters
    )
  end

  # A second dimension the summary is narrowed to, so a report grouped by agent
  # can be read for a single inbox and the other way around.
  def summary_filters
    {
      inbox_id: params[:inbox_id].presence,
      user_id: params[:user_id].presence
    }.compact
  end

  def filtered?
    summary_filters.any?
  end

  # Rows an agent (or inbox) has no part in are noise once the report is narrowed
  # to a single inbox (or agent), so they only survive while nothing is filtered.
  def reject_untouched_rows(reports)
    return reports unless filtered?

    reports.reject { |report| untouched_row?(report) }
  end

  def untouched_row?(report)
    report[:conversations_count].to_i.zero? &&
      report[:resolved_conversations_count].to_i.zero? &&
      report[:handled_conversations_count].to_i.zero? &&
      [report[:avg_resolution_time], report[:avg_first_response_time], report[:avg_reply_time]].all?(&:nil?)
  end

  def summary_dimension_type
    {
      'account_id' => 'account',
      'user_id' => 'agent',
      'inbox_id' => 'inbox',
      'conversations.team_id' => 'team'
    }.fetch(group_by_key.to_s)
  end
end
