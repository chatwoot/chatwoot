class Api::V1::Keycloak::LogoutController < ApplicationController
  def create
    token = params['token']
    session_info = KeycloakSessionInfo.find_by(browser_token: token)

    if session_info.present?
      id_token = session_info.metadata['id_token']
      if id_token.present?
        url = send_end_session_endpoint_to_url(id_token)
        session_info.destroy
        render json: { message: 'Logged out successfully', url: url }, status: :ok
      else
        render json: { message: 'No id_token found in metadata for the session' }, status: :ok
      end
    else
      render json: { message: 'No session found for the provided token' }, status: :ok
    end
  end

  private

  def send_end_session_endpoint_to_url(id_token)
    realm = ENV.fetch('KEYCLOAK_REALM', '')
    keycloak_url = ENV.fetch('KEYCLOAK_URL', '')
    end_session_end_point = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/logout")
    params = logout_params(id_token)
    end_session_params = URI.encode_www_form(params)
    "#{end_session_end_point}?#{end_session_params}"
  end

  def logout_params(id_token)
    {
      id_token_hint: id_token,
      post_logout_redirect_uri: ENV.fetch('FRONTEND_URL', '')
    }
  end
end
