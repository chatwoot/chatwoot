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
      business_hours: params[:business_hours]
    )
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
