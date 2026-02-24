class Api::V1::Accounts::AgentCapacityPoliciesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :check_authorization
  before_action :fetch_policy, only: [:show, :update, :destroy]

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
      exclusion_rules: [:exclude_older_than_hours, { excluded_labels: [] }]
    )
  end

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:id])
  end
end
