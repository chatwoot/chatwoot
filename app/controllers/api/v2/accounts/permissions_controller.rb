class Api::V2::Accounts::PermissionsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :find_account_user

  def show
    render json: @account_user.permissions
    # render 'api/v2/accounts/permissions', format: :json
  end

  def update
    permission_params.each do |feature, enabled|
      enabled ? @account_user.grant_access(feature) : @account_user.revoke_access(feature)
    end
    render json: @account_user.permissions
  end

  private

  def permission_params
    params.require(:permissions).permit!
  end

  def find_account_user
    @account_user = AccountUser.find_by(
      user_id: params[:user_id]
    )
  end
end
