module GoogleCalendar::IntegrationHelper
  def generate_google_calendar_token(account_id)
    return if client_secret.blank?

    JWT.encode({ sub: account_id, iat: Time.current.to_i }, client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Google Calendar token: #{e.message}")
    nil
  end

  def verify_google_calendar_token(token)
    return if token.blank? || client_secret.blank?

    JWT.decode(token, client_secret, true, { algorithm: 'HS256', verify_expiration: true }).first['sub']
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Google Calendar token: #{e.message}")
    nil
  end

  private

  def client_secret
    @client_secret ||= GlobalConfigService.load('GOOGLE_CALENDAR_CLIENT_SECRET', nil)
  end
end
