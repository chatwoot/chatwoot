Doorkeeper.configure do
  orm :active_record

  # The dashboard is a SPA, so the consent screen is a Vue page that calls JSON endpoints.
  api_only
  base_controller 'ApplicationController'

  resource_owner_authenticator { current_user || authenticate_user! }

  # Every client is public: no secrets, PKCE on every authorization.
  grant_flows %w[authorization_code]
  use_refresh_token
  force_pkce
  pkce_code_challenge_methods %w[S256]

  hash_token_secrets
  allow_token_introspection false

  # A token works for one account, which the user picks on the consent screen.
  custom_access_token_attributes [:account_id]

  default_scopes 'conversations:read', 'contacts:read'
  optional_scopes 'conversations:write', 'messages:write', 'contacts:write'
  enforce_configured_scopes
end
