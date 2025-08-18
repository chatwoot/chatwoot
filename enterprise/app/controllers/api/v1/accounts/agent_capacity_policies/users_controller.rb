class Api::V1::Accounts::AgentCapacityPolicies::UsersController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_policy
  before_action :check_admin_authorization?

  def assign
    @user = Current.account.users.find(params[:id])
    @account_user = Current.account.account_users.find_by!(user: @user)
    @account_user.update!(agent_capacity_policy: @agent_capacity_policy)
  end

  def unassign
    @user = Current.account.users.find(params[:id])
    @account_user = Current.account.account_users.find_by!(user: @user)
    @account_user.update!(agent_capacity_policy: nil)
  end

  private

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:agent_capacity_policy_id])
  end
end
