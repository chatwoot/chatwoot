class Api::V1::Accounts::AgentCapacityPoliciesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :check_feature_flag
  before_action :fetch_policy, only: [:show, :update, :destroy]
  before_action :check_authorization

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

  private

  def permitted_params
    params.require(:agent_capacity_policy).permit(
      :name,
      :description,
      exclusion_rules: [:overall_capacity, { hours: [], days: [] }]
    )
  end

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:id])
  end

  def check_authorization
    authorize(Enterprise::AgentCapacityPolicy)
  end

  def check_feature_flag
    render_not_found unless Current.account.feature_enabled?('assignment_v2')
  end
end
