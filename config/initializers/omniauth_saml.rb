Rails.application.config.middleware.use OmniAuth::Builder do
  if defined?(OmniAuth::MultiProvider)
    OmniAuth::MultiProvider.register(
      self,
      provider_name: :saml,
      identity_provider_id_regex: /\d+/,
      path_prefix: '/auth/saml'
    ) do |account_id, rack_env|
      # Find the account's SAML settings
      saml_settings = AccountSamlSettings.find_by(account_id: account_id, enabled: true)

      if saml_settings
        # Store the account in the rack environment for later use
        rack_env['chatwoot.account_id'] = account_id

        # Return the SAML provider options with correct option names
        {
          assertion_consumer_service_url: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/auth/saml/#{account_id}/callback",
          sp_entity_id: saml_settings.sp_entity_id_or_default,
          idp_sso_service_url: saml_settings.sso_url,
          idp_cert_fingerprint: saml_settings.certificate_fingerprint,
          idp_cert: saml_settings.certificate,
          name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
          attribute_statements: saml_settings.attribute_mappings || {
            email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'],
            name: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'],
            first_name: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'],
            last_name: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']
          }
        }
      end
    end
  end
end

OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
