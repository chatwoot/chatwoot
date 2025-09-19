class Api::V1::AuthController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:saml_login]
  before_action :find_user_and_account, only: [:saml_login]

  def saml_login
    return if @account.nil?

    saml_initiation_url = "/auth/saml?account_id=#{@account.id}"
    redirect_to saml_initiation_url, status: :temporary_redirect
  end

  private

  def find_user_and_account
    return unless validate_email_presence

    find_saml_enabled_account
  end

  def validate_email_presence
    @email = params[:email]&.downcase&.strip
    return true if @email.present?

    render json: { error: I18n.t('auth.saml.invalid_email') }, status: :bad_request
    false
  end

  def find_saml_enabled_account
    user = User.from_email(@email)
    return render_saml_error unless user

    account_user = find_account_with_saml(user)
    return render_saml_error unless account_user

    @account = account_user.account
  end

  def find_account_with_saml(user)
    user.account_users
        .joins(account: :saml_settings)
        .where.not(saml_settings: { sso_url: [nil, ''] })
        .where.not(saml_settings: { certificate: [nil, ''] })
        .find { |account_user| account_user.account.feature_enabled?('saml') }
  end

  def render_saml_error
    render json: { error: I18n.t('auth.saml.authentication_failed') }, status: :unauthorized
  end
end
