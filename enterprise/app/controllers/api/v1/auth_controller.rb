class Api::V1::AuthController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:saml_login]
  before_action :find_user_and_account, only: [:saml_login]

  def saml_login
    unless saml_sso_enabled?
      render json: { error: 'SAML SSO login is not enabled' }, status: :forbidden
      return
    end

    return if @account.nil?

    relay_state = params[:target] || 'web'

    saml_initiation_url = "/auth/saml?account_id=#{@account.id}&RelayState=#{relay_state}"
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
    error = 'saml-authentication-failed'

    if mobile_target?
      mobile_deep_link_base = GlobalConfigService.load('MOBILE_DEEP_LINK_BASE', 'chatwootapp')
      redirect_to "#{mobile_deep_link_base}://auth/saml?error=#{ERB::Util.url_encode(error)}", allow_other_host: true
    else
      redirect_to sso_login_page_url(error: error)
    end
  end

  def mobile_target?
    params[:target]&.casecmp('mobile')&.zero?
  end

  def sso_login_page_url(error: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    params = { error: error }.compact

    query = params.to_query
    query_fragment = query.present? ? "?#{query}" : ''

    "#{frontend_url}/app/login/sso#{query_fragment}"
  end

  def saml_sso_enabled?
    GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s == 'true'
  end
end
