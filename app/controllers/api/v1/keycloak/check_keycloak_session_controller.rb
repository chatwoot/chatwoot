class Api::V1::Keycloak::CheckKeycloakSessionController < ApplicationController
    def create
      email = params['email']
      session_info = KeycloakSessionsInfo.find_by(email: email)
  
      realm = ENV.fetch('KEYCLOAK_REALM', nil)
      keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
      token_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/token").to_s
      userinfo_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/userinfo").to_s
      client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
      client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil)
  
      if session_info.present?
        access_token = session_info.token_info['access_token']
        refresh_token = session_info.token_info['refresh_token']
        response = HTTParty.post(userinfo_url, {
                                   headers: {
                                     'Authorization' => "Bearer #{access_token}",
                                     'Content-Type' => 'application/x-www-form-urlencoded'
                                   }
                                 })
        puts response
      else
        # Handle case where no record is found for the email
      end
    end
  end
  