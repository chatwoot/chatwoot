class Api::V1::Accounts::SlaPoliciesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :ensure_sla_feature_enabled
  before_action :fetch_sla, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @sla_policies = Current.account.sla_policies
  end

  def show; end

  def create
    @sla_policy = Current.account.sla_policies.create!(permitted_params)
  end

  def update
    @sla_policy.update!(update_permitted_params)
  end

  def destroy
    ::DeleteObjectJob.perform_later(@sla_policy, Current.user, request.ip) if @sla_policy.present?
    head :ok
  end

  def permitted_params
    params.require(:sla_policy).permit(:name, :description, :first_response_time_threshold, :next_response_time_threshold,
                                       :resolution_time_threshold, :only_during_business_hours, notify_user_ids: [])
  end

  # Thresholds and business hours are locked after creation, conversations already
  # tracked against this SLA were measured using those values.
  def update_permitted_params
    params.require(:sla_policy).permit(:name, :description, notify_user_ids: [])
  end

  def fetch_sla
    @sla_policy = Current.account.sla_policies.find_by(id: params[:id])
  end

  def ensure_sla_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?('sla')
  end
end
