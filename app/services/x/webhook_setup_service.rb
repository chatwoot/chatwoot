class X::WebhookSetupService
  def self.ensure_webhook_registered
    new.ensure_webhook_registered
  end

  def ensure_webhook_registered
    webhook_id = GlobalConfigService.load('X_WEBHOOK_ID', nil)
    return webhook_id if webhook_id.present?

    webhook_id = register_webhook
    if webhook_id
      update_webhook_id(webhook_id)
      webhook_id
    end
  rescue StandardError => e
    Rails.logger.error "Failed to ensure X webhook registered: #{e.message}"
    nil
  end

  private

  def register_webhook
    webhook_url = "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/x"
    Rails.logger.info "Registering X webhook: #{webhook_url}"

    response = HTTParty.post(
      'https://api.x.com/2/webhooks',
      headers: { 'Authorization' => "Bearer #{app_bearer_token}", 'Content-Type' => 'application/json' },
      body: { url: webhook_url }.to_json
    )
    raise "X webhook registration failed (#{response.code}): #{extract_error_message(response)}" unless [200, 201].include?(response.code)

    extract_webhook_id(response)
  rescue StandardError => e
    Rails.logger.error "X webhook registration failed: #{e.message}"
    raise
  end

  def extract_webhook_id(response)
    data = response.parsed_response
    webhook_id = data.is_a?(Hash) ? (data.dig('data', 'id') || data['id']) : nil
    raise 'No webhook ID returned from X API' unless webhook_id

    Rails.logger.info "Successfully registered X webhook with ID: #{webhook_id}"
    webhook_id
  end

  def app_bearer_token
    @app_bearer_token ||= fetch_app_bearer_token
  end

  def fetch_app_bearer_token
    api_key = GlobalConfigService.load('X_API_KEY', '')
    api_secret = GlobalConfigService.load('X_API_SECRET', '')
    raise 'X app bearer token not available: configure X_API_KEY and X_API_SECRET' if api_key.blank? || api_secret.blank?

    credentials = Base64.strict_encode64("#{CGI.escape(api_key)}:#{CGI.escape(api_secret)}")
    response = HTTParty.post(
      'https://api.x.com/oauth2/token',
      headers: {
        'Authorization' => "Basic #{credentials}",
        'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8'
      },
      body: 'grant_type=client_credentials'
    )

    raise "X app bearer token fetch failed (#{response.code})" unless response.code == 200

    response.parsed_response['access_token']
  end

  def update_webhook_id(webhook_id)
    config = InstallationConfig.find_by(name: 'X_WEBHOOK_ID')
    if config
      config.update!(value: webhook_id)
    else
      InstallationConfig.create!(name: 'X_WEBHOOK_ID', value: webhook_id)
    end
    GlobalConfig.clear_cache
  end

  def extract_error_message(response)
    if response.parsed_response.is_a?(Hash)
      response.parsed_response.dig('errors', 0, 'message') ||
        response.parsed_response['error'] ||
        response.body
    else
      response.body
    end
  end
end
