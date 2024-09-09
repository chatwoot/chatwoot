class Api::V1::Keycloak::CheckKeycloakSessionController < ApplicationController
  def create
    token = params['token']
    session_info = KeycloakSessionInfo.find_by(browser_token: token)

    if session_info.present?
      access_token = session_info.metadata['access_token']
      keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
      realm = ENV.fetch('KEYCLOAK_REALM', nil)
      user_info_endpoint = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/userinfo")

      user_info_res = HTTParty.get(user_info_endpoint, {
                                     headers: {
                                       'Authorization': "Bearer #{access_token}",
                                       'Content-Type': 'application/x-www-form-urlencoded'
                                     }
                                   })
      if user_info_res.code.to_i == 200
        render json: { message: 'Session is active' }, status: :ok
      else
        session_info.destroy
        render json: { message: 'Session expired. Please log in again' }, status: :ok
      end
    else
      render json: { message: 'No session found for the provided token' }, status: :ok
    end
  end
end
