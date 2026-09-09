class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  include EmailHelper

  SHOPIFY_INSTALL_REDIRECT_PATTERN = %r{\Asettings/integrations/shopify\?shopify_pending_install=([0-9a-f]{32})\z}

  def omniauth_success
    get_resource_from_auth_hash

    @resource.present? ? sign_in_user(redirect_url: oauth_redirect_url) : sign_up_user
  end

  private

  def sign_in_user(redirect_url: nil)
    # Capture before skip_confirmation! sets confirmed_at, which would
    # make oauth_user_needs_password_reset? return false and skip the
    # password reset for persisted unconfirmed users.
    needs_password_reset = oauth_user_needs_password_reset?
    @resource.skip_confirmation! if confirmable_enabled?
    set_random_password_if_oauth_user if needs_password_reset

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    redirect_to login_page_url(
      email: encoded_email,
      sso_auth_token: @resource.generate_sso_auth_token,
      redirect_url: redirect_url
    )
  end

  def sign_in_user_on_mobile
    # See comment in sign_in_user for why this is captured before skip_confirmation!
    needs_password_reset = oauth_user_needs_password_reset?
    @resource.skip_confirmation! if confirmable_enabled?
    set_random_password_if_oauth_user if needs_password_reset

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    params = { email: encoded_email, sso_auth_token: @resource.generate_sso_auth_token }.to_query

    mobile_deep_link_base = GlobalConfigService.load('MOBILE_DEEP_LINK_BASE', 'chatwootapp')
    redirect_to "#{mobile_deep_link_base}://auth/saml?#{params}", allow_other_host: true
  end

  def sign_up_user
    return redirect_to login_page_url(error: 'no-account-found') unless account_signup_allowed?
    return redirect_to login_page_url(error: 'business-account-only') unless validate_signup_email_is_business_domain?

    create_account_for_user
    set_random_password_if_oauth_user
    token = @resource.send(:set_reset_password_token)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    redirect_to "#{frontend_url}/app/auth/password/edit?config=default&reset_password_token=#{token}"
  end

  def login_page_url(error: nil, email: nil, sso_auth_token: nil, redirect_url: nil)
    frontend_url = omniauth_frontend_url
    params = { email: email, sso_auth_token: sso_auth_token, redirect_url: redirect_url }.compact
    params[:error] = error if error.present?

    "#{frontend_url}/app/login?#{params.to_query}"
  end

  def omniauth_frontend_url
    ENV.fetch('FRONTEND_URL', nil)
  end

  def oauth_redirect_url
    redirect_url = params[:state].to_s
    redirect_url if redirect_url.match?(SHOPIFY_INSTALL_REDIRECT_PATTERN)
  end

  def account_signup_allowed?
    return true if GlobalConfigService.account_signup_enabled?

    Shopify::FeatureGate.enabled? && Shopify::PendingInstallation.pending?(token: shopify_pending_install_token)
  end

  def shopify_pending_install_token
    @shopify_pending_install_token ||= oauth_redirect_url&.match(SHOPIFY_INSTALL_REDIRECT_PATTERN)&.captures&.first
  end

  def resource_class(_mapping = nil)
    User
  end

  def get_resource_from_auth_hash # rubocop:disable Naming/AccessorMethodName
    email = auth_hash.dig('info', 'email')
    @resource = resource_class.from_email(email)
  end

  def validate_signup_email_is_business_domain?
    # return true if the user is a business account, false if it is a blocked domain account
    Account::SignUpEmailValidationService.new(auth_hash['info']['email']).perform
  rescue CustomExceptions::Account::InvalidEmail
    false
  end

  def create_account_for_user
    attributes = {
      account_name: extract_domain_without_tld(auth_hash['info']['email']),
      user_full_name: auth_hash['info']['name'],
      email: auth_hash['info']['email'],
      locale: I18n.locale,
      confirmed: auth_hash['info']['email_verified']
    }
    pending_install_token = shopify_pending_install_token
    attributes[:shopify_pending_install_token] = pending_install_token if pending_install_token

    builder_class = pending_install_token.present? ? Shopify::SignupService : AccountBuilder
    @resource, @account = builder_class.new(**attributes).perform
    Avatar::AvatarFromUrlJob.perform_later(@resource, auth_hash['info']['image'])
  end

  def oauth_user_needs_password_reset?
    @resource.present? && (@resource.new_record? || !@resource.confirmed?)
  end

  def set_random_password_if_oauth_user
    # Password must satisfy secure_password requirements (uppercase, lowercase, number, special char)
    @resource.update(password: "#{SecureRandom.hex(16)}aA1!") if @resource.persisted?
  end

  def default_devise_mapping
    'user'
  end
end

DeviseOverrides::OmniauthCallbacksController.prepend_mod_with('DeviseOverrides::OmniauthCallbacksController')
