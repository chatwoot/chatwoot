class Api::V1::Accounts::AgentCapacityPolicies::UserAssignmentsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_policy
  before_action :check_admin_authorization?

  def create
    @user = Current.account.users.find(params[:user_id])
    @account_user = Current.account.account_users.find_by!(user: @user)
    @account_user.update!(agent_capacity_policy: @agent_capacity_policy)
  end

  def destroy
    @user = Current.account.users.find(params[:user_id])
    @account_user = Current.account.account_users.find_by!(user: @user)
    @account_user.update!(agent_capacity_policy: nil)
  end

  private

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:agent_capacity_policy_id])
  end
end
