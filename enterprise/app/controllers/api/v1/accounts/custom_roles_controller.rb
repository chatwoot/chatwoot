class Api::V1::Accounts::CustomRolesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :ensure_custom_roles_feature_enabled
  before_action :fetch_custom_role, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @custom_roles = Current.account.custom_roles
  end

  def show; end

  def create
    @custom_role = Current.account.custom_roles.create!(permitted_params)
  end

  def update
    @custom_role.update!(permitted_params)
  end

  def destroy
    @custom_role.destroy!
    head :ok
  end

  def permitted_params
    params.require(:custom_role).permit(:name, :description, permissions: [])
  end

  def fetch_custom_role
    @custom_role = Current.account.custom_roles.find_by(id: params[:id])
  end

  def ensure_custom_roles_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?('custom_roles')
  end
end
