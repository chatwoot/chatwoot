OmniAuth.config.full_host = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', nil), ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', nil), {
    provider_ignores_state: true
  }

  # SAML provider with setup phase for multi-tenant configuration
  provider :saml,
           setup: lambda { |env|
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
               settings = AccountSamlSettings.find_by(account_id: account_id, enabled: true)

               if settings
                 # Configure the strategy options dynamically
                 env['omniauth.strategy'].options[:assertion_consumer_service_url] = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/omniauth/saml/callback?account_id=#{account_id}"
                 env['omniauth.strategy'].options[:sp_entity_id] = settings.sp_entity_id_or_default
                 env['omniauth.strategy'].options[:idp_sso_service_url] = settings.sso_url
                 env['omniauth.strategy'].options[:idp_cert] = settings.certificate
                 env['omniauth.strategy'].options[:name_identifier_format] = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
               else
                 # Set a dummy certificate to avoid the error
                 env['omniauth.strategy'].options[:idp_cert] = 'DUMMY'
               end
             else
               # Set a dummy certificate to avoid the error
               env['omniauth.strategy'].options[:idp_cert] = 'DUMMY'
             end
           }
end
