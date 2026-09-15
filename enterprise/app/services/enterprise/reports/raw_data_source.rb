module Enterprise::Reports::RawDataSource
  def aggregate
    return super unless elasticsearch_report?

    elasticsearch_report.aggregate || super
  end

  def timeseries
    return super unless elasticsearch_report?

    elasticsearch_report.timeseries || super
  end

  private

  def elasticsearch_report?
    ::Reports::ElasticsearchMessageReport::MESSAGE_TYPES.key?(metric.to_s) &&
      %w[account inbox].include?(dimension_type) && range.present? &&
      ChatwootApp.advanced_search_allowed? &&
      account.feature_enabled?('advanced_search_indexing') &&
      account.feature_enabled?('elasticsearch_reports')
  end

  def elasticsearch_report
    @elasticsearch_report ||= ::Reports::ElasticsearchMessageReport.new(
      account: account, metric: metric, dimension_type: dimension_type,
      dimension_id: dimension_id, range: range, group_by: group_by, timezone: timezone
    )
  end
end
