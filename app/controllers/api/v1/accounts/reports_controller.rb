class Api::V1::Accounts::ReportsController < Api::BaseController
  include CustomExceptions::Report
  include Constants::Report

  around_action :report_exception

  def account
    builder = ReportBuilder.new(current_account, account_report_params)
    data = builder.build
    render json: data
  end

  def agent
    builder = ReportBuilder.new(current_account, agent_report_params)
    data = builder.build
    render json: data
  end

  def account_summary
    render json: account_summary_metrics
  end

  def agent_summary
    render json: agent_summary_metrics
  end

  private

  def report_exception
    yield
  rescue InvalidIdentity, IdentityNotFound, MetricNotFound, InvalidStartTime, InvalidEndTime => e
    render_error_response(e)
  end

  def current_account
    current_user.account
  end

  def account_summary_metrics
    summary_metrics(ACCOUNT_METRICS, :account_summary_params, AVG_ACCOUNT_METRICS)
  end

  def agent_summary_metrics
    summary_metrics(AGENT_METRICS, :agent_summary_params, AVG_AGENT_METRICS)
  end

  def summary_metrics(metrics, calc_function, avg_metrics)
    metrics.each_with_object({}) do |metric, result|
      data = ReportBuilder.new(current_account, send(calc_function, metric)).build
      result[metric] = calculate_metric(data, metric, avg_metrics)
    end
  end

  def calculate_metric(data, metric, avg_metrics)
    sum = data.inject(0) { |val, hash| val + hash[:value].to_i }
    if avg_metrics.include?(metric)
      sum /= data.length unless sum.zero?
    end
    sum
  end

  def account_summary_params(metric)
    {
      metric: metric.to_s,
      type: :account,
      since: params[:since],
      until: params[:until]
    }
  end

  def agent_summary_params(metric)
    {
      metric: metric.to_s,
      type: :agent,
      since: params[:since],
      until: params[:until],
      id: params[:id]
    }
  end

  def account_report_params
    {
      metric: params[:metric],
      type: :account,
      since: params[:since],
      until: params[:until]
    }
  end

  def agent_report_params
    {
      metric: params[:metric],
      type: :agent,
      id: params[:id],
      since: params[:since],
      until: params[:until]
    }
  end
end
