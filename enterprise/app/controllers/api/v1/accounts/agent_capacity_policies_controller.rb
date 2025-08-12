class Api::V1::Accounts::AgentCapacityPoliciesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_policy, only: [:show, :update, :destroy, :assign_user, :unassign_user, :update_inbox_limit]
  before_action :check_enterprise_authorization

  def index
    @agent_capacity_policies = Current.account.agent_capacity_policies
  end

  def show; end

  def create
    @agent_capacity_policy = Current.account.agent_capacity_policies.create!(permitted_params)
  end

  def update
    @agent_capacity_policy.update!(permitted_params)
  end

  def destroy
    @agent_capacity_policy.destroy!
    head :ok
  end

  def assign_user
    user = Current.account.users.find(params[:user_id])
    account_user = Current.account.account_users.find_by!(user: user)
    account_user.update!(agent_capacity_policy: @agent_capacity_policy)
    render json: { message: 'User assigned successfully' }
  end

  def unassign_user
    user = Current.account.users.find(params[:user_id])
    account_user = Current.account.account_users.find_by!(user: user)
    account_user.update!(agent_capacity_policy: nil)
    render json: { message: 'User unassigned successfully' }
  end

  def update_inbox_limit
    inbox = Current.account.inboxes.find(params[:inbox_id])
    inbox_limit = @agent_capacity_policy.inbox_capacity_limits.find_or_initialize_by(inbox: inbox)
    inbox_limit.update!(conversation_limit: params[:conversation_limit])
    render json: inbox_limit
  end

  private

  def permitted_params
    params.require(:agent_capacity_policy).permit(:name, :description, exclusion_rules: {})
  end

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:id])
  end

  def check_enterprise_authorization
    authorize(Enterprise::AgentCapacityPolicy)
  end
end
