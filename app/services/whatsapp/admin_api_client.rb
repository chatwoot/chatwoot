class Whatsapp::AdminApiClient
  class AdminApiError < StandardError
    attr_reader :code, :http_status

    def initialize(message, code: nil, http_status: nil)
      super(message)
      @code = code
      @http_status = http_status
    end
  end

  class NotConfiguredError < AdminApiError; end
  class UnauthorizedError < AdminApiError; end
  class NotFoundError < AdminApiError; end
  class ConflictError < AdminApiError; end

  def initialize(account)
    @account = account
    validate_configuration!
  end

  # POST /admin/instances - Create a new WhatsApp instance
  def create_instance(port:, webhook: nil, webhook_secret: nil, basic_auth: nil, **options)
    body = {
      port: port,
      webhook: webhook,
      webhook_secret: webhook_secret,
      basic_auth: basic_auth,
      debug: options[:debug] || false,
      auto_mark_read: options[:auto_mark_read] || true,
      chat_storage: options[:chat_storage] || false
    }.compact

    response = HTTParty.post(
      "#{base_url}/admin/instances",
      headers: api_headers,
      body: body.to_json,
      timeout: 30
    )

    handle_response(response, 'create_instance')
  end

  # GET /admin/instances - List all WhatsApp instances
  def list_instances
    response = HTTParty.get(
      "#{base_url}/admin/instances",
      headers: api_headers,
      timeout: 15
    )

    handle_response(response, 'list_instances')
  end

  # GET /admin/instances/{port} - Get details of a specific instance
  def get_instance(port)
    response = HTTParty.get(
      "#{base_url}/admin/instances/#{port}",
      headers: api_headers,
      timeout: 15
    )

    handle_response(response, 'get_instance')
  end

  # PATCH /admin/instances/{port} - Update instance configuration
  def update_instance(port, config)
    response = HTTParty.patch(
      "#{base_url}/admin/instances/#{port}",
      headers: api_headers,
      body: config.to_json,
      timeout: 30
    )

    handle_response(response, 'update_instance')
  end

  # DELETE /admin/instances/{port} - Delete a WhatsApp instance
  def delete_instance(port)
    response = HTTParty.delete(
      "#{base_url}/admin/instances/#{port}",
      headers: api_headers,
      timeout: 30
    )

    handle_response(response, 'delete_instance')
  end

  # GET /healthz - Health check endpoint
  def health_check
    response = HTTParty.get(
      "#{base_url}/healthz",
      timeout: 10
    )

    response.success?
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP ADMIN API] Health check failed: #{e.message}"
    false
  end

  # GET /readyz - Readiness check endpoint
  def readiness_check
    response = HTTParty.get(
      "#{base_url}/readyz",
      timeout: 10
    )

    response.success?
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP ADMIN API] Readiness check failed: #{e.message}"
    false
  end

  # Helper to check if Admin API is configured and healthy
  def self.configured_for?(account)
    account.whatsapp_admin_api_base_url.present? && account.whatsapp_admin_api_token.present?
  end

  def self.healthy?(account)
    return false unless configured_for?(account)

    new(account).health_check
  rescue NotConfiguredError
    false
  end

  private

  def validate_configuration!
    return if @account.whatsapp_admin_api_base_url.present? && @account.whatsapp_admin_api_token.present?

    raise NotConfiguredError, 'WhatsApp Admin API is not configured for this account'
  end

  def base_url
    @account.whatsapp_admin_api_base_url.chomp('/')
  end

  def api_headers
    {
      'Authorization' => "Bearer #{@account.whatsapp_admin_api_token}",
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response, operation)
    log_response(response, operation)

    case response.code
    when 200, 201
      parse_response_data(response)
    when 400
      error_data = parse_error(response)
      raise AdminApiError.new(error_data[:message], code: error_data[:code], http_status: 400)
    when 401
      raise UnauthorizedError.new('Invalid or missing bearer token', http_status: 401)
    when 404
      error_data = parse_error(response)
      raise NotFoundError.new(error_data[:message], code: error_data[:code], http_status: 404)
    when 409
      error_data = parse_error(response)
      raise ConflictError.new(error_data[:message], code: error_data[:code], http_status: 409)
    when 500, 502, 503
      error_data = parse_error(response)
      raise AdminApiError.new(error_data[:message], code: error_data[:code], http_status: response.code)
    else
      raise AdminApiError.new("Unexpected response: #{response.code}", http_status: response.code)
    end
  end

  def parse_response_data(response)
    return {} if response.body.blank?

    parsed = JSON.parse(response.body)
    # Admin API returns { data: {...}, message: "...", request_id: "...", timestamp: "..." }
    parsed['data'] || parsed
  rescue JSON::ParserError
    {}
  end

  def parse_error(response)
    return { message: 'Unknown error', code: 'unknown' } if response.body.blank?

    parsed = JSON.parse(response.body)
    {
      message: parsed['message'] || parsed['error'] || 'Unknown error',
      code: parsed['error'] || 'unknown'
    }
  rescue JSON::ParserError
    { message: response.body, code: 'parse_error' }
  end

  def log_response(response, operation)
    Rails.logger.debug do
      "[WHATSAPP ADMIN API] #{operation} - Status: #{response.code}, Body: #{response.body&.truncate(500)}"
    end
  end
end
