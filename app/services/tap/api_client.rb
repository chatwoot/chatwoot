class Tap::ApiClient
  include HTTParty

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  API_BASE_URL = 'https://api.tap.company/v2'.freeze

  attr_reader :secret_key

  def initialize(secret_key:)
    @secret_key = secret_key

    validate_secret_key!
  end

  def create_invoice(invoice_params)
    response = self.class.post(
      "#{API_BASE_URL}/invoices",
      request_options(invoice_params)
    )
    handle_response(response)
  end

  private

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
