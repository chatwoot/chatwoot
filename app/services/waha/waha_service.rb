class Waha::WahaService
  include Singleton

  API_BASE = ENV.fetch('WAHA_API_URL', nil)

  def initialize
    @access_token = nil
    @token_expires_at = nil
  end

  def ensure_authenticated
    return @access_token if token_valid?

    login
  end

  def login
    return nil unless waha_configured?

    response = HTTParty.post(
      "#{API_BASE}/auth/login",
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' },
      body: {
        username: ENV.fetch('WAHA_USERNAME', nil),
        password: ENV.fetch('WAHA_PASSWORD', nil)
      }.to_json
    )

    raise 'Login failed' unless response.success?

    @access_token = response.parsed_response.dig('data', 'access_token')
    @token_expires_at = 1.hour.from_now
    @access_token
  rescue StandardError => e
    Rails.logger.error "WAHA login failed: #{e.message}"
    nil
  end

  def create_device(phone_number:, webhook_url: nil)
    return { error: 'WAHA not configured' } unless waha_configured?

    # Ensure we have valid authentication token for device creation
    ensure_authenticated

    return { error: 'Failed to authenticate with WAHA' } unless @access_token

    # Use provided webhook_url or generate one
    webhook = webhook_url || webhook_url_for(phone_number)

    response = HTTParty.post(
      "#{API_BASE}/devices",
      headers: auth_headers,
      body: {
        phone_number: phone_number,
        webhook: webhook
      }.to_json
    )

    raise "Failed to create device: #{response.body}" unless response.success?

    response.parsed_response
  rescue StandardError => e
    Rails.logger.error "WAHA create device failed: #{e.message}"
    { error: e.message }
  end

  def initialize_whatsapp_session(api_key:)
    response = HTTParty.post(
      "#{API_BASE}/whatsapp/session",
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'X-API-Key' => api_key
      }
    )

    raise "Failed to initialize session: #{response.body}" unless response.success?

    response.parsed_response
  end

  def get_qr_code_base64(api_key:)
    response = HTTParty.get(
      "#{API_BASE}/whatsapp/session/qr",
      headers: {
        'Accept' => 'application/json',
        'X-API-Key' => api_key
      }
    )

    return response.parsed_response if response.success?

    raise "Failed to get QR code: #{response.body}"
  end

  def get_session_status(api_key:)
    response = HTTParty.get(
      "#{API_BASE}/whatsapp/status",
      headers: {
        'Accept' => 'application/json',
        'X-API-Key' => api_key
      }
    )

    response.success? ? response.parsed_response : nil
  end

  def send_message(api_key:, phone_number:, message:, **options)
    payload = {
      phone_number: phone_number,
      message: message
    }

    payload[:image_url] = options[:image_url] if options[:image_url].present?
    payload[:document_url] = options[:document_url] if options[:document_url].present?
    payload[:video_url] = options[:video_url] if options[:video_url].present?

    response = HTTParty.post(
      "#{API_BASE}/whatsapp/session/send",
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'X-API-Key' => api_key
      },
      body: payload.to_json
    )

    JSON.parse(response.body)
  end

  private

  def token_valid?
    @access_token.present? && @token_expires_at.present? && Time.current < @token_expires_at
  end

  def auth_headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{@access_token}"
    }
  end

  def webhook_url_for(phone_number)
    Rails.application.routes.url_helpers.waha_callback_url(
      host: current_application_url,
      phone_number: phone_number
    )
  end

  def current_application_url
    # Priority: FRONTEND_URL env var, then fallback
    ENV.fetch('FRONTEND_URL', detect_current_url || 'http://localhost:3000')
  end

  def detect_current_url
    # Try to get URL from current request context if available
    return nil unless defined?(Current) && Current.respond_to?(:request)
    
    request = Current.request
    return nil unless request&.respond_to?(:base_url)
    
    request.base_url
  rescue StandardError
    nil
  end

  def waha_configured?
    ENV.fetch('WAHA_API_URL', nil).present? &&
      ENV.fetch('WAHA_USERNAME', nil).present? &&
      ENV.fetch('WAHA_PASSWORD', nil).present?
  end
end