class Api::V1::Keycloak::CheckKeycloakSessionController < ApplicationController
    def create
      email = params['email']
      session_info = KeycloakSessionsInfo.find_by(email: email)
  
      realm = ENV.fetch('KEYCLOAK_REALM', nil)
      keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
      introspect_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/token/introspect").to_s
      client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
      client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil)
  
      if session_info.present?
        access_token = session_info.token_info['access_token']
        # Introspect access_token is active or expired
        introspect_res = HTTParty.post(introspect_url, {
          body: {
            'client_id': client_id,
            'client_secret': client_secret,
            'token': access_token
          }
        })
        if introspect_res["active"]===false
          render json: { message: 'Session expired. Please log in again.' }
        end
      else
        render json: { message: 'No Session Info.' }
      end
    end
  end
  