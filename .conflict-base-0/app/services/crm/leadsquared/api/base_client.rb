class Crm::Leadsquared::Api::BaseClient
  include HTTParty

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  def initialize(access_key, secret_key, endpoint_url)
    @access_key = access_key
    @secret_key = secret_key
    @base_uri = endpoint_url
  end

  def get(path, params = {})
    full_url = URI.join(@base_uri, path).to_s

    options = {
      query: params,
      headers: headers
    }

    response = self.class.get(full_url, options)
    handle_response(response)
  end

  def post(path, params = {}, body = {})
    full_url = URI.join(@base_uri, path).to_s

    options = {
      query: params,
      headers: headers
    }

    options[:body] = body.to_json if body.present?

    response = self.class.post(full_url, options)
    handle_response(response)
  end

  private

  def headers
    {
      'Content-Type': 'application/json',
      'x-LSQ-AccessKey': @access_key,
      'x-LSQ-SecretKey': @secret_key
    }
  end

  def handle_response(response)
    case response.code
    when 200..299
      handle_success(response)
    else
      error_message = "LeadSquared API error: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise ApiError.new(error_message, response.code, response)
    end
  end

  def handle_success(response)
    parse_response(response)
  rescue JSON::ParserError, TypeError => e
    error_message = "Failed to parse LeadSquared API response: #{e.message}"
    raise ApiError.new(error_message, response.code, response)
  end

  def parse_response(response)
    body = response.parsed_response

    if body.is_a?(Hash) && body['Status'] == 'Error'
      error_message = body['ExceptionMessage'] || 'Unknown API error'
      raise ApiError.new(error_message, response.code, response)
    else
      body
    end
  end
end
