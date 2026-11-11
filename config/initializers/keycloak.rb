# Keycloak (OIDC) sign-in. Everything custom lives in app/services/keycloak/ and is attached to the
# upstream classes by Keycloak::Patches.apply!, so upstream files stay untouched.
Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV['KEYCLOAK_ISSUER'].present?
    # Trust the (self-signed) certificate of a local Keycloak served over HTTPS, e.g. the shared MIS Keycloak.
    if ENV['KEYCLOAK_CA_FILE'].present?
      trust_keycloak_ca = ->(config) { config.ssl.ca_file = ENV.fetch('KEYCLOAK_CA_FILE') }
      ::OpenIDConnect.http_config(&trust_keycloak_ca)
      ::Rack::OAuth2.http_config(&trust_keycloak_ca)
    end

    # KEYCLOAK_INTERNAL_URL lets the server reach Keycloak on a different host than browsers (e.g. inside Docker)
    keycloak_issuer = ENV.fetch('KEYCLOAK_ISSUER')
    keycloak_internal = ENV['KEYCLOAK_INTERNAL_URL'].presence
    oidc_endpoints = if keycloak_internal
                       {
                         authorization_endpoint: "#{keycloak_issuer}/protocol/openid-connect/auth",
                         token_endpoint: "#{keycloak_internal}/protocol/openid-connect/token",
                         userinfo_endpoint: "#{keycloak_internal}/protocol/openid-connect/userinfo",
                         jwks_uri: "#{keycloak_internal}/protocol/openid-connect/certs"
                       }
                     else
                       {}
                     end

    provider :openid_connect, {
      name: :openid_connect,
      issuer: keycloak_issuer,
      discovery: keycloak_internal.blank?,
      scope: [:openid, :email, :profile],
      response_type: :code,
      pkce: true,
      client_options: {
        identifier: ENV.fetch('KEYCLOAK_CLIENT_ID', nil),
        secret: ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil),
        redirect_uri: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/omniauth/openid_connect/callback"
      }.merge(oidc_endpoints)
    }
  end
end

Rails.application.config.to_prepare { Keycloak::Patches.apply! }
