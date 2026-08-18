class Integrations::GoogleCalendar::TokenService
  TOKEN_EXPIRY_BUFFER = 5.minutes

  def initialize(connection:)
    @connection = connection
  end

  def access_token
    return connection.access_token if token_valid?

    refresh!
  end

  private

  attr_reader :connection

  def token_valid?
    return false if connection.access_token.blank? || connection.access_token_expires_at.blank?

    connection.access_token_expires_at > Time.current.utc + TOKEN_EXPIRY_BUFFER
  end

  def refresh!
    tokens = Integrations::GoogleCalendar::Oauth.refresh_access_token(connection.refresh_token)
    expires_in = tokens['expires_in'].to_i
    expires_in = 3600 if expires_in.zero?

    connection.update!(
      access_token: tokens['access_token'],
      access_token_expires_at: Time.current.utc + expires_in.seconds
    )
    connection.access_token
  end
end
