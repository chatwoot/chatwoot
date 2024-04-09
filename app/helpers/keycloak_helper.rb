module KeycloakHelper
    def redirectToKeycloak()
        realm = ENV.fetch('KEYCLOAK_REALM', nil);
        client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
        redirect_uri = ENV.fetch('KEYCLOAK_CALLBACK_URL', nil)
        keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
        base_url = "#{keycloak_url}/realms/#{realm}/protocol/openid-connect/auth";
        response_type = 'code';
        scope = 'openid';
  
        query_string = new URLSearchParams({
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: response_type,
          scope: scope,
        }).toString();
  
        "#{base_url}?#{query_string}";
    end
end
