class Api::V1::Profile::OauthApplicationsController < Api::BaseController
  include MfaEnforcementGuard

  before_action :check_user_mfa_enforcement, if: :authenticate_by_access_token?

  def index
    tokens = Doorkeeper::AccessToken.active_for(current_user).includes(:application)

    @tokens_by_application = tokens.group_by(&:application)
    @account_names = Account.where(id: tokens.map(&:account_id)).pluck(:id, :name).to_h
    # Refreshing replaces the token, so the latest consent is the time the user connected the app.
    @authorized_at = Doorkeeper::AccessGrant.where(resource_owner_id: current_user.id).group(:application_id).maximum(:created_at)
  end

  def destroy
    application = Doorkeeper::Application.authorized_for(current_user).find(params[:id])
    Doorkeeper::Application.revoke_tokens_and_grants_for(application.id, current_user)
    head :ok
  end
end
