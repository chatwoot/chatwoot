class V2::Reports::Conversations::BaseReportBuilder
  pattr_initialize :account, :params

  private

  def builder_class(metric)
    return unless Reports::ReportMetricRegistry.supported?(metric)

    V2::Reports::Timeseries::ReportBuilder
  end

  def log_invalid_metric
    Rails.logger.error "ReportBuilder: Invalid metric - #{params[:metric]}"

    {}
  end
end
