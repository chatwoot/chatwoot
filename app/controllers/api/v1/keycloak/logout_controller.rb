class Api::V1::Keycloak::LogoutController < ApplicationController
    def logout_from_keycloak
      email = params['email']
      session_info = KeycloakSessionsInfo.find_by(email: email)
  
      realm = ENV.fetch('KEYCLOAK_REALM', nil)
      keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
      token_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/token").to_s
      logout_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/logout").to_s
      client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
      client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil)
  
      if session_info.present?
        access_token = session_info.token_info['access_token']
        refresh_token = session_info.token_info['refresh_token']
        response = HTTParty.post(logout_url, {
                                   body: {
                                     client_id: client_id,
                                     client_secret: client_secret,
                                     refresh_token: refresh_token
                                   },
                                   headers: {
                                     'Authorization' => "Bearer #{access_token}",
                                     'Content-Type' => 'application/x-www-form-urlencoded'
                                   }
                                 })
      else
        # Handle case where no record is found for the email
      end
    end
  end