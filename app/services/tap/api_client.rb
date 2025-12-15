class Tap::ApiClient
  include HTTParty

  base_uri 'https://api.tap.company/v2'
  default_timeout 60

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  attr_reader :secret_key

  def initialize(secret_key:)
    @secret_key = secret_key

    validate_secret_key!
  end

  def create_invoice(invoice_params)
    response = self.class.post('/invoices', request_options(invoice_params))
    handle_response(response)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error "Tap API timeout: #{e.message}"
    raise ApiError.new('Tap API request timed out. Please try again.', 'timeout', nil)
  end

  def get_invoice(invoice_id)
    response = self.class.get("/invoices/#{invoice_id}", headers: auth_headers)
    handle_response(response)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error "Tap API timeout: #{e.message}"
    raise ApiError.new('Tap API request timed out. Please try again.', 'timeout', nil)
  end

  private

  def auth_headers
    {
      'Authorization' => "Bearer #{secret_key}",
      'accept' => 'application/json'
    }
  end

  def validate_secret_key!
    return if secret_key.present?

    raise ArgumentError, 'Tap secret key is required'
  end

  def request_options(params)
    {
      headers: {
        'Authorization' => "Bearer #{secret_key}",
        'Content-Type' => 'application/json'
      },
      body: params.to_json
    }
  end

  def handle_response(response)
    return response.parsed_response if response.success?

    Rails.logger.error "Tap API error: #{response.code} - #{response.body}"
    raise ApiError.new("Tap API error: #{response.code}", response.code, response)
  end
end
