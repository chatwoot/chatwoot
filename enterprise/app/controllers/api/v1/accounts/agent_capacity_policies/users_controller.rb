class Api::V1::Accounts::AgentCapacityPolicies::UsersController < Api::V1::Accounts::EnterpriseAccountsController
  before_action -> { check_authorization(AgentCapacityPolicy) }
  before_action :fetch_policy
  before_action :fetch_user, only: [:destroy]

  def index
    @users = User.joins(:account_users)
                 .where(account_users: { account_id: Current.account.id, agent_capacity_policy_id: @agent_capacity_policy.id })
  end

  def create
    @account_user = Current.account.account_users.find_by!(user_id: permitted_params[:user_id])
    @account_user.update!(agent_capacity_policy: @agent_capacity_policy)
    @user = @account_user.user
  end

  def destroy
    @account_user.update!(agent_capacity_policy: nil)
    head :ok
  end

  private

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:agent_capacity_policy_id])
  end

  def fetch_user
    @account_user = Current.account.account_users.find_by!(user_id: params[:id])
  end

  def permitted_params
    params.permit(:user_id)
  end
end
