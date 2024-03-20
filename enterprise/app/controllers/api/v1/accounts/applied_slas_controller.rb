class Api::V1::Accounts::AppliedSlasController < Api::V1::Accounts::EnterpriseAccountsController
  include Sift
  include DateRangeHelper

  before_action :set_sla_responses, only: [:metrics]
  before_action :check_admin_authorization?

  sort_on :created_at, type: :datetime

  def metrics
    total_applied_slas = @sla_responses.count
    missed_applied_slas = @sla_responses.where(sla_status: :missed).count
    @hit_percentage = total_applied_slas.zero? ? 0 : ((total_applied_slas - missed_applied_slas) / total_applied_slas.to_f) * 100
    @number_of_breaches = missed_applied_slas
  end

  private

  def set_sla_responses
    base_query = Current.account.applied_slas.left_joins(:conversation)
    base_query = base_query.where(conversations: { cached_label_list: params[:label_list] }) if params[:label_list].present?
    base_query = base_query.where(conversations: { assigned_agent_id: params[:user_ids] }) if params[:assigned_agent_id].present?
    @sla_responses = filtrate(base_query).filter_by_created_at(range)
                                         .filter_by_inbox_id(params[:inbox_id])
                                         .filter_by_team_id(params[:team_id])
                                         .filter_by_sla_policy_id(params[:sla_policy_id])
  end
end
