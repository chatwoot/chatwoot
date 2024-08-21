class Api::V1::Keycloak::CreateRedirectUrlController < ApplicationController
  def create
    realm = ENV.fetch('KEYCLOAK_REALM', nil)
    keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
    base_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/auth").to_s
    client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
    redirect_uri = ENV.fetch('KEYCLOAK_CALLBACK_URL', nil)
    response_type = 'code'
    scope = 'openid'

    query_params = {
      client_id: client_id,
      redirect_uri: redirect_uri,
      response_type: response_type,
      scope: scope
    }
    query_string = URI.encode_www_form(query_params)
    render json: { message: 'Keycloak redirect url', url: "#{base_url}?#{query_string}" }, status: :ok
  end
end
