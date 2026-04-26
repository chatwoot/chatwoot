# Be sure to restart your server when you modify this file.
#
# Note: While the main API uses token-based authentication (devise_token_auth),
# sessions are still required for the super_admin dashboard (flash messages, CSRF).
# The session cookie is not used for regular user authentication.

Rails.application.config.session_store :cookie_store,
                                       key: ENV.fetch('SESSION_COOKIE_KEY', '_chatwoot_session'),
                                       same_site: :lax,
                                       secure: Rails.env.production?,
                                       httponly: true
