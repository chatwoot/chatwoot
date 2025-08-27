class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  include EmailHelper
  
  # Handle the redirect from OmniAuth for SAML
  def redirect_callbacks
    Rails.logger.debug "[redirect_callbacks] Provider: #{params[:provider]}"
    Rails.logger.debug "[redirect_callbacks] Params: #{params.inspect}"
    
    # For SAML, we need to preserve the account_id through the redirect
    if params[:provider] == 'saml' && params[:account_id]
      session[:saml_account_id] = params[:account_id]
    end
    
    # Redirect to the auth callback path, preserving the method and body
    redirect_to "/auth/#{params[:provider]}/callback", status: 307
  end

  # SAML-specific callback to handle the provider
  def saml
    Rails.logger.debug "[SAML Callback] Called saml method"
    Rails.logger.debug "[SAML Callback] Auth hash: #{request.env['omniauth.auth'].inspect}"
    Rails.logger.debug "[SAML Callback] Params: #{params.inspect}"
    
    # Set auth hash for parent class if needed
    self.auth_hash = request.env['omniauth.auth']
    
    # Call the generic success handler
    omniauth_success
  end
  
  def omniauth_success
    Rails.logger.debug "[OmniAuth Callback] Starting omniauth_success"
    Rails.logger.debug "[OmniAuth Callback] request.env keys: #{request.env.keys.select { |k| k.to_s.include?('omniauth') }}"
    
    auth_hash = request.env['omniauth.auth'] || auth_hash  # auth_hash is from parent class
    Rails.logger.debug "[OmniAuth Callback] Auth hash from env: #{request.env['omniauth.auth'].inspect}"
    Rails.logger.debug "[OmniAuth Callback] Auth hash from method: #{auth_hash.inspect if defined?(auth_hash)}"
    
    if auth_hash
      Rails.logger.debug "[OmniAuth Callback] Provider: #{auth_hash['provider']}"
      Rails.logger.debug "[OmniAuth Callback] Info: #{auth_hash['info'].inspect}"
      Rails.logger.debug "[OmniAuth Callback] UID: #{auth_hash['uid']}"
      Rails.logger.debug "[OmniAuth Callback] Extra: #{auth_hash['extra'].inspect if auth_hash['extra']}"
    else
      Rails.logger.debug "[OmniAuth Callback] No auth hash found!"
    end
    
    Rails.logger.debug "[OmniAuth Callback] Session SAML account: #{session[:saml_account_id]}"
    Rails.logger.debug "[OmniAuth Callback] Params: #{params.inspect}"
    Rails.logger.debug "[OmniAuth Callback] OmniAuth params: #{request.env['omniauth.params']}"
    
    # For SAML, check if account has SAML enabled
    if auth_hash && auth_hash['provider'] == 'saml'
      account_id = params[:account_id] || session[:saml_account_id] || request.env['omniauth.params']&.dig('account_id')
      if account_id
        saml_settings = AccountSamlSettings.find_by(account_id: account_id, enabled: true)
        unless saml_settings
          Rails.logger.error "[OmniAuth Callback] SAML not enabled for account #{account_id}"
          return redirect_to login_page_url(error: 'saml-not-enabled')
        end
      end
    end
    
    get_resource_from_auth_hash

    @resource.present? ? sign_in_user : sign_up_user
  end

  private

  def sign_in_user
    @resource.skip_confirmation! if confirmable_enabled?

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    redirect_to login_page_url(email: encoded_email, sso_auth_token: @resource.generate_sso_auth_token)
  end

  def sign_up_user
    return redirect_to login_page_url(error: 'no-account-found') unless account_signup_allowed?
    return redirect_to login_page_url(error: 'business-account-only') unless validate_signup_email_is_business_domain?

    create_account_for_user
    token = @resource.send(:set_reset_password_token)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    redirect_to "#{frontend_url}/app/auth/password/edit?config=default&reset_password_token=#{token}"
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
    Rails.logger.debug "[get_resource_from_auth_hash] auth_hash: #{auth_hash.inspect}"
    Rails.logger.debug "[get_resource_from_auth_hash] auth_hash class: #{auth_hash.class}"
    
    # Check if auth_hash is available from parent class method
    if auth_hash.nil? && defined?(super)
      Rails.logger.debug "[get_resource_from_auth_hash] Calling parent auth_hash method"
      auth_hash
    end
    
    if auth_hash
      Rails.logger.debug "[get_resource_from_auth_hash] Looking for user with email: #{auth_hash['info']['email']}"
      # find the user with their email instead of UID and token
      @resource = resource_class.where(
        email: auth_hash['info']['email']
      ).first
      Rails.logger.debug "[get_resource_from_auth_hash] Found resource: #{@resource.inspect}"
    else
      Rails.logger.error "[get_resource_from_auth_hash] No auth_hash available!"
    end
  end

  def validate_signup_email_is_business_domain?
    # return true if the user is a business account, false if it is a blocked domain account
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
