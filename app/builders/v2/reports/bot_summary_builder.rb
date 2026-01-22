class V2::Reports::BotSummaryBuilder
  include DateRangeHelper

  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params  = params
  end

  def build
    {
      date_range: date_range,
      bot_metrics: bot_metrics,
      bot_summary: bot_summary,
      bot_resolutions_data: bot_resolutions_data,
      bot_handoffs_data: bot_handoffs_data
    }
  end

  private

  def date_range
    {
      since: Time.zone.at(params[:since].to_i),
      until: Time.zone.at(params[:until].to_i)
    }
  end

  def bot_metrics
    V2::Reports::BotMetricsBuilder
      .new(account, since_until_params)
      .metrics
  end

  def bot_summary
    metric_builder.bot_summary
  end

  def bot_resolutions_data
    report_builder('bot_resolutions_count').timeseries
  end

  def bot_handoffs_data
    report_builder('bot_handoffs_count').timeseries
  end

  def metric_builder
    @metric_builder ||=
      V2::Reports::Conversations::MetricBuilder.new(account, summary_params)
  end

  def report_builder(metric)
    V2::Reports::Conversations::ReportBuilder.new(
      account,
      summary_params.merge(metric: metric)
    )
  end

  def summary_params
    {
      type: :account,
      since: params[:since],
      until: params[:until],
      group_by: params[:group_by] || 'day',
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
    }
  end

  def since_until_params
    {
      since: params[:since],
      until: params[:until]
    }
  end
end
