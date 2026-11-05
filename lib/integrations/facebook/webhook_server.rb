class Integrations::Facebook::WebhookServer < Facebook::Messenger::Server
  private

  def check_integrity
    if app_secret_for(parsed_body.dig('entry', 0, 'id')).blank?
      Rails.logger.error('Rejected Facebook webhook: FB_APP_SECRET is not configured')
      raise Facebook::Messenger::BadRequestError, 'Error checking message integrity'
    end

    super
  end
end
