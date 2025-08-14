class Api::V1::Accounts::AgentCapacityPolicies::UsersController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :check_feature_flag
  before_action :fetch_policy
  before_action :check_authorization

  def assign
    @user = Current.account.users.find(params[:user_id])
    @account_user = Current.account.account_users.find_by!(user: @user)
    @account_user.update!(agent_capacity_policy: @agent_capacity_policy)
  end

  def unassign
    @user = Current.account.users.find(params[:user_id])
    @account_user = Current.account.account_users.find_by!(user: @user)
    @account_user.update!(agent_capacity_policy: nil)
  end

  private

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:agent_capacity_policy_id])
  end

  def check_authorization
    authorize(Enterprise::AgentCapacityPolicy)
  end

  def check_feature_flag
    render_not_found unless Current.account.feature_enabled?('assignment_v2')
  end
end
