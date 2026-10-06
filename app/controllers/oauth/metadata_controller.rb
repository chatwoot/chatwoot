# Authorization server metadata, as defined in RFC 8414.
class Oauth::MetadataController < ApplicationController
  def show
    base_url = ENV.fetch('FRONTEND_URL')

    render json: {
      issuer: base_url,
      authorization_endpoint: "#{base_url}/oauth/authorize",
      token_endpoint: "#{base_url}/oauth/token",
      registration_endpoint: "#{base_url}/oauth/register",
      revocation_endpoint: "#{base_url}/oauth/revoke",
      scopes_supported: Doorkeeper.config.scopes.to_a,
      response_types_supported: ['code'],
      grant_types_supported: Oauth::RegistrationsController::GRANT_TYPES,
      token_endpoint_auth_methods_supported: [Oauth::RegistrationsController::TOKEN_ENDPOINT_AUTH_METHOD],
      code_challenge_methods_supported: Doorkeeper.config.pkce_code_challenge_methods
    }
  end
end
