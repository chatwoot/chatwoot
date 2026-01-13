module Enterprise::DeviseOverrides::OmniauthCallbacksController
  def saml
    # Call parent's omniauth_success which handles the auth
    omniauth_success
  end

  def redirect_callbacks
    # derive target redirect route from 'resource_class' param, which was set
    # before authentication.
    devise_mapping = get_devise_mapping
    redirect_route = get_redirect_route(devise_mapping)

    # preserve omniauth info for success route. ignore 'extra' in twitter
    # auth response to avoid CookieOverflow.
    session['dta.omniauth.auth'] = request.env['omniauth.auth'].except('extra')
    session['dta.omniauth.params'] = request.env['omniauth.params']

    # For SAML, use 303 See Other to convert POST to GET and preserve session
    if params[:provider] == 'saml'
      redirect_to redirect_route, { status: 303 }.merge(redirect_options)
    else
      super
    end
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
    return super unless params[:provider] == 'saml'

    relay_state = saml_relay_state
    error = params[:message] || 'authentication-failed'

    if for_mobile?(relay_state)
      redirect_to_mobile_error(error, relay_state)
    else
      redirect_to login_page_url(error: "saml-#{error}")
    end
  end

  private

  def handle_saml_auth
    account_id = extract_saml_account_id
    relay_state = saml_relay_state

    unless saml_enabled_for_account?(account_id)
      return redirect_to_mobile_error('saml-not-enabled') if for_mobile?(relay_state)

      return redirect_to login_page_url(error: 'saml-not-enabled')
    end

    @resource = SamlUserBuilder.new(auth_hash, account_id).perform

    if @resource.persisted?
      return sign_in_user_on_mobile if for_mobile?(relay_state)

      sign_in_user
    else
      return redirect_to_mobile_error('saml-authentication-failed') if for_mobile?(relay_state)

      redirect_to login_page_url(error: 'saml-authentication-failed')
    end
  end

  def extract_saml_account_id
    params[:account_id] || session[:saml_account_id] || request.env['omniauth.params']&.dig('account_id')
  end

  def saml_relay_state
    session[:saml_relay_state] || request.env['omniauth.params']&.dig('RelayState')
  end

  def for_mobile?(relay_state)
    relay_state.to_s.casecmp('mobile').zero?
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
