class Api::V1::ReportsController < Api::BaseController
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

  def agent
    @agent ||= current_account.users.find(params[:agent_id])
  end

  def account_summary_metrics
    ACCOUNT_METRICS.each_with_object({}) do |metric, result|
      data = ReportBuilder.new(current_account, account_summary_params(metric)).build

      if AVG_ACCOUNT_METRICS.include?(metric)
        sum = data.inject(0) { |sum, hash| sum + hash[:value].to_i }
        sum /= data.length unless sum.zero?
      else
        sum = data.inject(0) { |sum, hash| sum + hash[:value].to_i }
      end

      result[metric] = sum
    end
  end

  def agent_summary_metrics
    AGENT_METRICS.each_with_object({}) do |metric, result|
      data = ReportBuilder.new(current_account, agent_summary_params(metric)).build

      if AVG_AGENT_METRICS.include?(metric)
        sum = data.inject(0) { |sum, hash| sum + hash[:value].to_i }
        sum /= data.length unless sum.zero?
      else
        sum = data.inject(0) { |sum, hash| sum + hash[:value].to_i }
      end

      result[metric] = sum
    end
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
