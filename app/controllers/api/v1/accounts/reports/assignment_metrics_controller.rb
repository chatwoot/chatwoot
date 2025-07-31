# frozen_string_literal: true

class Api::V1::Accounts::Reports::AssignmentMetricsController < Api::V1::Accounts::BaseController
  include AssignmentMetricsHelper
  include DistributionMetrics

  before_action :check_authorization
  before_action :validate_date_range

  def index
    @metrics = metrics_service.compute_assignment_metrics
    render json: { assignment_metrics: @metrics }
  end

  def agent_history
    history_service = Reports::AgentHistoryService.new(Current.account, params)

    if params[:agent_id].present?
      @agent = Current.account.users.find(params[:agent_id])
      @assignment_history = history_service.fetch_agent_assignment_history(@agent)

      render json: {
        agent: serialize_agent(@agent),
        assignment_history: @assignment_history,
        meta: pagination_meta
      }
    else
      agents_summary = history_service.compute_all_agents_history
      render json: { agents_history: agents_summary }
    end
  end

  def policy_performance
    @policies = Current.account.assignment_policies.includes(:inboxes)
    performance_data = @policies.map do |policy|
      metrics_service.compute_policy_performance(policy)
    end

    render json: { policy_performance: performance_data }
  end

  def agent_utilization
    agents = Current.account.users.joins(:account_users).where(account_users: { role: %w[agent administrator] })
    utilization_data = agents.map do |agent|
      metrics_service.compute_agent_utilization(agent)
    end

    render json: { agent_utilization: utilization_data }
  end

  def assignment_distribution
    distribution_data = {
      by_inbox: metrics_service.compute_distribution_by_inbox,
      by_team: metrics_service.compute_distribution_by_team,
      by_hour: metrics_service.compute_distribution_by_hour,
      by_day_of_week: compute_distribution_by_day_of_week
    }

    render json: { assignment_distribution: distribution_data }
  end

  def export
    type = params[:type] || 'csv'
    data = metrics_service.compute_assignment_metrics

    case type
    when 'csv'
      export_service = Reports::AssignmentExportService.new(data)
      send_data export_service.generate_csv, filename: "assignment_metrics_#{Date.current}.csv", type: 'text/csv'
    when 'json'
      send_data data.to_json, filename: "assignment_metrics_#{Date.current}.json", type: 'application/json'
    else
      render json: { error: 'Unsupported export type' }, status: :bad_request
    end
  end

  private

  def validate_date_range
    return if params[:since].blank? || params[:until].blank?

    start_date = Date.parse(params[:since])
    end_date = Date.parse(params[:until])

    if start_date > end_date
      render json: { error: 'Start date must be before end date' }, status: :unprocessable_entity
    elsif (end_date - start_date).to_i > 365
      render json: { error: 'Date range cannot exceed 365 days' }, status: :unprocessable_entity
    end
  rescue Date::Error
    render json: { error: 'Invalid date format' }, status: :unprocessable_entity
  end

  def check_authorization
    authorize Current.account, :show_metrics?
  end

  def metrics_service
    @metrics_service ||= Reports::AssignmentMetricsService.new(Current.account, params)
  end
end
