module GoogleConcern
  extend ActiveSupport::Concern

  GOOGLE_CALENDAR_SCOPE = 'https://www.googleapis.com/auth/calendar'.freeze

  def google_client
    creds = ::EmailOauth::CredentialResolver.new(oauth_account, 'google').credentials

    ::OAuth2::Client.new(creds[:client_id], creds[:client_secret], {
                           site: 'https://oauth2.googleapis.com',
                           authorize_url: 'https://accounts.google.com/o/oauth2/auth',
                           token_url: 'https://accounts.google.com/o/oauth2/token'
                         })
  end

  private

  def scope
    base_scope = 'email profile https://mail.google.com/'
    return base_scope unless request_calendar_scope?

    "#{base_scope} #{GOOGLE_CALENDAR_SCOPE}"
  end

  # Calendar is a first-class capability of every Google mailbox connection: the scope is
  # always requested (one consent) unless a self-hosted install explicitly disables it via
  # EMAIL_OAUTH_CALENDAR_SCOPE_ENABLED (distinct from the CRM meetings product flag).
  def request_calendar_scope?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('EMAIL_OAUTH_CALENDAR_SCOPE_ENABLED', true))
  end
end
