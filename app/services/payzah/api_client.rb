require 'base64'

class Payzah::ApiClient
  include HTTParty

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  attr_reader :api_key, :api_url

  def initialize(api_key:)
    @api_key = api_key
    @api_url = ENV.fetch('PAYZAH_API_URL', 'https://development.payzah.net/ws/paymentgateway/index')

    validate_api_key!
  end

  def create_payment(payment_params)
    response = self.class.post(@api_url, request_options(payment_params))
    handle_response(response)
  end

  private

  def validate_api_key!
    return if api_key.present?

    raise ArgumentError, 'Payzah API key is required'
  end

  def request_options(payment_params)
    {
      headers: {
        'Authorization' => Base64.strict_encode64(api_key),
        'Content-Type' => 'application/json'
      },
      body: payment_params.to_json
    }
  end

  def handle_response(response)
    return response.parsed_response if response.success?

    Rails.logger.error "Payzah API error: #{response.code} - #{response.body}"
    raise ApiError.new("Payzah API error: #{response.code}", response.code, response)
  end
end
