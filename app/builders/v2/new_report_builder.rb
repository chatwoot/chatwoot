class V2::NewReportBuilder < V2::BaseConversationReportBuilder
  include DateRangeHelper

  pattr_initialize :account, :params

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
