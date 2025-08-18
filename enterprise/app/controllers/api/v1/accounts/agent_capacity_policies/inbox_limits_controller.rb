class Api::V1::Accounts::AgentCapacityPolicies::InboxLimitsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_policy
  before_action :fetch_inbox
  before_action :check_admin_authorization?

  def update
    @inbox_limit = @agent_capacity_policy.inbox_capacity_limits.find_or_initialize_by(inbox: @inbox)
    @inbox_limit.update!(inbox_limit_params)
  end

  private

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:agent_capacity_policy_id])
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
  end

  def inbox_limit_params
    params.permit(:conversation_limit)
  end
end
