# Be sure to restart your server when you modify this file.
# Sessions are used only for the super_admin dashboard (flash/CSRF), not for API auth.

secure_cookies = ActiveModel::Type::Boolean.new.cast(ENV.fetch('FORCE_SSL', false))

Rails.application.config.session_store :cookie_store,
                                       key: '_chatwoot_session',
                                       same_site: :lax,
                                       secure: secure_cookies,
                                       httponly: true
