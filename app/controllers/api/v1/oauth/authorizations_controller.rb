class Api::V1::Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  def create
    # The token will only work for this account, so the user must belong to it.
    unless current_user.account_users.exists?(account_id: params[:account_id])
      return render_could_not_create_error(I18n.t('oauth.authorizations.invalid_account'))
    end

    super
  end
end
