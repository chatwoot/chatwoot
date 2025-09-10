# Enterprise Edition SAML SSO Provider
# This initializer adds SAML authentication support for Enterprise customers
# Handle IdP-initiated Single Logout (SLO) session destruction
SAML_SLO_SESSION_DESTROY_PROC = proc do |env, _session|
  # Extract user info from SAML logout request
  logout_request = env['omniauth.strategy'].response_object
  name_id = logout_request.name_id if logout_request.respond_to?(:name_id)

  next unless name_id

  # Find user by email and verify it's a SAML user
  user = User.from_email(name_id)
  user&.logout_all_sessions! if user&.provider == 'saml'
end

# SAML setup proc for multi-tenant configuration
SAML_SETUP_PROC = proc do |env|
  request = ActionDispatch::Request.new(env)

  # Extract account_id from various sources
  account_id = request.params['account_id'] ||
               request.session[:saml_account_id] ||
               env['omniauth.params']&.dig('account_id')

  if account_id
    # Store in session and omniauth params for callback
    request.session[:saml_account_id] = account_id
    env['omniauth.params'] ||= {}
    env['omniauth.params']['account_id'] = account_id

    # Find SAML settings for this account
    settings = AccountSamlSettings.find_by(account_id: account_id)

    if settings
      # Configure the strategy options dynamically
      env['omniauth.strategy'].options[:assertion_consumer_service_url] = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/omniauth/saml/callback?account_id=#{account_id}"
      env['omniauth.strategy'].options[:sp_entity_id] = settings.sp_entity_id
      env['omniauth.strategy'].options[:idp_entity_id] = settings.idp_entity_id
      env['omniauth.strategy'].options[:idp_sso_service_url] = settings.sso_url
      env['omniauth.strategy'].options[:idp_cert] = settings.certificate
      env['omniauth.strategy'].options[:name_identifier_format] = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
      env['omniauth.strategy'].options[:idp_slo_session_destroy] = SAML_SLO_SESSION_DESTROY_PROC
    else
      # Set a dummy certificate to avoid the error
      env['omniauth.strategy'].options[:idp_cert] = 'DUMMY'
    end
  else
    # Set a dummy certificate to avoid the error
    env['omniauth.strategy'].options[:idp_cert] = 'DUMMY'
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  # SAML provider with setup phase for multi-tenant configuration
  provider :saml, setup: SAML_SETUP_PROC
end
