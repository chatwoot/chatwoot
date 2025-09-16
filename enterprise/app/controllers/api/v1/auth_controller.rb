class Api::V1::AuthController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:saml_login]
  before_action :find_user_and_account, only: [:saml_login]

  def saml_login
    saml_initiation_url = "/auth/saml?account_id=#{@account.id}"

    render json: {
      redirect_url: saml_initiation_url
    }
  end

  private

  def find_user_and_account
    @email = params[:email]&.downcase&.strip

    return render json: { error: I18n.t('auth.saml.invalid_email') }, status: :bad_request if @email.blank?

    user = User.from_email(@email)

    return render_saml_error unless user

    # Find first account with SAML enabled for this user
    account_user = user.account_users
                       .joins(account: :saml_settings)
                       .where.not(saml_settings: { sso_url: [nil, ''] })
                       .where.not(saml_settings: { certificate: [nil, ''] })
                       .first

    return render_saml_error unless account_user

    @account = account_user.account

    # Check if account has enterprise features and SAML enabled
    return render_saml_error unless @account&.feature_enabled?('saml')
  end

  def render_saml_error
    render json: { error: I18n.t('auth.saml.authentication_failed') }, status: :unauthorized
  end
end
