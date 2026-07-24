module Enterprise::DeviseOverrides::OmniauthCallbacksController
  def redirect_callbacks
    return omniauth_success if params[:provider] == 'saml'

    super
  end

  def omniauth_success
    case auth_hash&.dig('provider')
    when 'saml'
      handle_saml_auth
    else
      super
    end
  end

  def omniauth_failure
    return super unless params[:strategy] == 'saml'

    relay_state = saml_relay_state
    error = params[:message] || 'authentication-failed'

    if for_mobile?(relay_state)
      redirect_to_mobile_error(error)
    else
      redirect_to login_page_url(error: "saml-#{error}")
    end
  end

  private

  def create_account_for_user
    super
    record_marketing_attribution
  end

  def record_marketing_attribution
    return if @account.blank?

    Internal::Accounts::MarketingAttributionService.new(account: @account, cookies: cookies).perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def handle_saml_auth
    account_id = extract_saml_account_id
    relay_state = saml_relay_state

    return handle_saml_auth_error(relay_state, 'saml-not-enabled') unless saml_enabled_for_account?(account_id)

    @resource = SamlUserBuilder.new(auth_hash, account_id).perform

    return sign_in_saml_user(relay_state) if @resource.persisted?

    handle_saml_auth_error(relay_state, 'saml-authentication-failed')
  rescue SamlUserBuilder::AuthenticationFailed
    handle_saml_auth_error(relay_state, 'saml-authentication-failed')
  end

  def extract_saml_account_id
    params[:account_id] || request.env['omniauth.params']&.dig('account_id')
  end

  def saml_relay_state
    params[:RelayState] || request.env['omniauth.params']&.dig('RelayState')
  end

  def auth_hash
    request.env['omniauth.auth'] || super
  end

  def for_mobile?(relay_state)
    relay_state.to_s.casecmp('mobile').zero?
  end

  def sign_in_saml_user(relay_state)
    return sign_in_user_on_mobile if for_mobile?(relay_state)

    sign_in_user
  end

  def handle_saml_auth_error(relay_state, error)
    return redirect_to_mobile_error(error) if for_mobile?(relay_state)

    redirect_to login_page_url(error: error)
  end

  def redirect_to_mobile_error(error)
    mobile_deep_link_base = GlobalConfigService.load('MOBILE_DEEP_LINK_BASE', 'chatwootapp')
    redirect_to "#{mobile_deep_link_base}://auth/saml?error=#{ERB::Util.url_encode(error)}", allow_other_host: true
  end

  def saml_enabled_for_account?(account_id)
    return false if account_id.blank?

    account = Account.find_by(id: account_id)

    return false if account.nil?
    return false unless account.feature_enabled?('saml')

    AccountSamlSettings.find_by(account_id: account_id).present?
  end
end
