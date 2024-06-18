class V2::Reports::Conversations::ReportBuilder < V2::Reports::Conversations::BaseReportBuilder
  def timeseries
    perform_action(:timeseries)
  end

  def aggregate_value
    perform_action(:aggregate_value)
  end

  private

  def perform_action(method_name)
    return builder.new(account, params).public_send(method_name) if builder.present?

    log_invalid_metric
  end

  def builder
    builder_class(params[:metric])
  end
end
