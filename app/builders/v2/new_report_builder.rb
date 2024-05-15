class V2::NewReportBuilder
  include DateRangeHelper

  pattr_initialize :account, :params

  AVG_METRICS = %w[avg_first_response_time avg_resolution_time reply_time].freeze
  COUNT_METRICS = %w[conversations_count incoming_messages_count outgoing_messages_count resolutions_count bot_resolutions_count
                     bot_handoffs_count].freeze

  DEFAULT_GROUP_BY = 'day'.freeze
  AGENT_RESULTS_PER_PAGE = 25

  def build
    builder_class = case params[:metric]
                    when *AVG_METRICS
                      V2::Reports::Timeseries::AverageReportBuilder
                    when *COUNT_METRICS
                      V2::Reports::Timeseries::MetricCountReportBuilder
                    else
                      log_invalid_metric
                      return {}
                    end

    builder_class.new(account, params).build
  end

  private

  def log_invalid_metric
    Rails.logger.error "ReportBuilder: Invalid metric - #{params[:metric]}"
  end
end
