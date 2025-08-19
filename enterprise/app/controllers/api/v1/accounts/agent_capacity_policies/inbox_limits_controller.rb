class Api::V1::Accounts::AgentCapacityPolicies::InboxLimitsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_policy
  before_action :fetch_inbox
  before_action :fetch_inbox_limit, only: [:update, :destroy]
  before_action :check_admin_authorization?

  def create
    @inbox_limit = @agent_capacity_policy.inbox_capacity_limits.create!(
      inbox: @inbox,
      conversation_limit: inbox_limit_params[:conversation_limit]
    )
  end

  def update
    @inbox_limit.update!(inbox_limit_params)
  end

  def destroy
    @inbox_limit.destroy!
    head :no_content
  end

  private

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:agent_capacity_policy_id])
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def fetch_inbox_limit
    @inbox_limit = @agent_capacity_policy.inbox_capacity_limits.find_by!(inbox: @inbox)
  end

  def inbox_limit_params
    params.permit(:conversation_limit)
  end
end
