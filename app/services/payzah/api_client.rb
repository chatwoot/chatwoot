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

  def initialize
    @api_key = ENV.fetch('PAYZAH_API_KEY', nil)
    @api_url = ENV.fetch('PAYZAH_API_URL', 'https://development.payzah.net/ws/paymentgateway/index')
  end

  def create_payment(payment_params)
    options = {
      headers: headers,
      body: payment_params.to_json
    }

    response = self.class.post(@api_url, options)
    handle_response(response)
  end

  private

  def headers
    {
      'Authorization' => Base64.strict_encode64(@api_key),
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response)
    case response.code
    when 200..299
      handle_success(response)
    else
      error_message = "Payzah API error: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise ApiError.new(error_message, response.code, response)
    end
  end

  def handle_success(response)
    parse_response(response)
  rescue JSON::ParserError, TypeError => e
    error_message = "Failed to parse Payzah API response: #{e.message}"
    raise ApiError.new(error_message, response.code, response)
  end

  def parse_response(response)
    response.parsed_response
  end
end
