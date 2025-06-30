class Integrations::Zalo::Client
  class Error < StandardError; end
  class AuthError < Error; end

  SUCCESS_CODE = 0
  AUTH_ERROR_CODE = -216

  DEFAULT_BASE_URL = 'https://openapi.zalo.me'.freeze
  private_constant :DEFAULT_BASE_URL

  def initialize(base_url = nil)
    @base_url = base_url.presence || DEFAULT_BASE_URL
    @headers = {}
    @body = {}
    @query = {}
    @form_data = false
    @urlencoded = false
  end

  def headers(options = {})
    @headers.merge!(options)
    self
  end

  def body(body = {})
    @body.merge!(body)
    self
  end

  def query(query = {})
    @query.merge!(query)
    self
  end

  def form_data!
    @form_data = true
    self
  end

  def urlencoded!
    @urlencoded = true
    self
  end

  def post(endpoint = nil)
    url = [@base_url, endpoint].compact.join('/')
    handle_response do
      HTTParty.post(url, query: @query, body: request_body, headers: request_headers)
    end
  end

  def get(endpoint = nil)
    url = [@base_url, endpoint].compact.join('/')
    handle_response do
      HTTParty.get(url, query: @query, headers: request_headers)
    end
  end

  private

  def request_body
    @form_data || @urlencoded ? @body : @body.to_json
  end

  def request_headers
    content_type = 'application/json'
    content_type = 'application/x-www-form-urlencoded' if @urlencoded
    content_type = 'multipart/form-data' if @form_data
    {
      'Content-Type' => content_type,
      'Accept' => 'application/json'
    }.merge(@headers)
  end

  def handle_response
    response = yield
    raise Error, "API Error: #{response.message}" unless response.success?

    res_json = response.parsed_response
    return res_json unless res_json.key?('error')

    case res_json['error']
    when SUCCESS_CODE
      return res_json['data'] || {}
    when AUTH_ERROR_CODE
      raise AuthError
    else
      raise Error, "API Error: #{res_json['message']}, Code: #{res_json['error']}"
    end
  rescue HTTParty::Error => e
    raise Error, "Network Error: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "Parse Error: #{e.message}"
  end
end
