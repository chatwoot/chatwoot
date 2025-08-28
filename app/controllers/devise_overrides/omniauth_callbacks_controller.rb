class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  include EmailHelper

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
      redirect_to redirect_route, { status: 307 }.merge(redirect_options)
    end
  end

  def omniauth_success
    case auth_hash&.dig('provider')
    when 'saml'
      handle_saml_auth
    else
      handle_standard_auth
    end
  end

  private

  def handle_saml_auth
    account_id = extract_saml_account_id

    return redirect_to login_page_url(error: 'saml-not-enabled'), allow_other_host: true if account_id && !saml_enabled_for_account?(account_id)

    @resource = SamlUserBuilder.new(auth_hash, account_id: account_id).perform

    if @resource.persisted?
      sign_in_user
    else
      redirect_to login_page_url(error: 'saml-authentication-failed'), allow_other_host: true
    end
  end

  def handle_standard_auth
    get_resource_from_auth_hash
    @resource.present? ? sign_in_user : sign_up_user
  end

  def extract_saml_account_id
    params[:account_id] || session[:saml_account_id] || request.env['omniauth.params']&.dig('account_id')
  end

  def saml_enabled_for_account?(account_id)
    AccountSamlSettings.find_by(account_id: account_id, enabled: true).present?
  end

  def sign_in_user
    @resource.skip_confirmation! if confirmable_enabled?

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    redirect_to login_page_url(email: encoded_email, sso_auth_token: @resource.generate_sso_auth_token), allow_other_host: true
  end

  def sign_up_user
    return redirect_to login_page_url(error: 'no-account-found'), allow_other_host: true unless account_signup_allowed?
    return redirect_to login_page_url(error: 'business-account-only'), allow_other_host: true unless validate_signup_email_is_business_domain?

    create_account_for_user
    token = @resource.send(:set_reset_password_token)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    redirect_to "#{frontend_url}/app/auth/password/edit?config=default&reset_password_token=#{token}", allow_other_host: true
  end

  def login_page_url(error: nil, email: nil, sso_auth_token: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    params = { email: email, sso_auth_token: sso_auth_token }.compact
    params[:error] = error if error.present?

    "#{frontend_url}/app/login?#{params.to_query}"
  end

  def account_signup_allowed?
    # set it to true by default, this is the behaviour across the app
    GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false') != 'false'
  end

  def resource_class(_mapping = nil)
    User
  end

  def get_resource_from_auth_hash # rubocop:disable Naming/AccessorMethodName
    return unless auth_hash

    email = auth_hash.dig('info', 'email')
    return unless email

    @resource = resource_class.from_email(email)
  end

  def validate_signup_email_is_business_domain?
    # return true if the user is a business account, false if it is a blocked domain account
    return false unless auth_hash&.dig('info', 'email')

    Account::SignUpEmailValidationService.new(auth_hash['info']['email']).perform
  rescue CustomExceptions::Account::InvalidEmail
    false
  end

  def create_account_for_user
    @resource, @account = AccountBuilder.new(
      account_name: extract_domain_without_tld(auth_hash['info']['email']),
      user_full_name: auth_hash['info']['name'],
      email: auth_hash['info']['email'],
      locale: I18n.locale,
      confirmed: auth_hash['info']['email_verified']
    ).perform
    Avatar::AvatarFromUrlJob.perform_later(@resource, auth_hash['info']['image'])
  end

  def default_devise_mapping
    'user'
  end
end
