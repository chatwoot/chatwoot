class Integrations::Facebook::WebhookServer < Facebook::Messenger::Server
  private

  def check_integrity
    if app_secret_for(parsed_body.dig('entry', 0, 'id')).blank?
      Rails.logger.error('Rejected Facebook webhook: FB_APP_SECRET is not configured')
      raise Facebook::Messenger::BadRequestError, 'Error checking message integrity'
    end

    super
  end

  def app_secret_for(facebook_page_id)
    @app_secrets ||= {}
    return @app_secrets[facebook_page_id] if @app_secrets.key?(facebook_page_id)

    @app_secrets[facebook_page_id] = super
  end
end
