class Api::V1::Accounts::SlaPoliciesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_sla, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @sla_policies = Current.account.sla_policies
  end

  def create
    @sla_policy = Current.account.sla_policies.create!(permitted_params)
  end

  def show; end

  def update
    @sla_policy.update!(permitted_params)
  end

  def destroy
    @sla_policy.destroy!
    head :ok
  end

  def permitted_params
    params.require(:sla_policy).permit(:name, :rt_threshold, :frt_threshold, :only_during_business_hours)
  end

  def fetch_sla
    @sla_policy = Current.account.sla_policies.find_by(id: params[:id])
  end
end
