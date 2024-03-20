class Api::V1::Accounts::AppliedSlasController < Api::V1::Accounts::EnterpriseAccountsController
  include Sift
  include DateRangeHelper

  before_action :set_sla_responses, only: [:metrics]
  before_action :check_admin_authorization?

  def metrics
    @total_applied_slas = @sla_responses.count
    @number_of_sla_breaches = @sla_responses.missed.count
  end

  private

  def set_sla_responses
    @sla_responses = initial_query
                     .filter_by_date_range(range)
                     .filter_by_inbox_id(params[:inbox_id])
                     .filter_by_team_id(params[:team_id])
                     .filter_by_sla_policy_id(params[:sla_policy_id])
                     .filter_by_label_list(params[:label_list])
                     .filter_by_assigned_agent_id(params[:assigned_agent_id])
  end

  def initial_query
    Current.account.applied_slas.includes(:conversation)
  end
end
