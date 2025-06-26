class Integrations::Zalo::Client
  class Error < StandardError; end

  DEFAULT_BASE_URL = 'https://openapi.zalo.me'.freeze
  private_constant :DEFAULT_BASE_URL

  def initialize(base_url = nil)
    @base_url = base_url.presence || DEFAULT_BASE_URL
    @headers = {}
    @body = {}
    @query = {}
  end

  def headers(headers = {})
    @headers.merge!(headers)
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

  def post(endpoint = nil)
    url = [@base_url, endpoint].compact.join('/')
    handle_response do
      Faraday.post(url, @body, @headers) do |req|
        req.params.merge!(@query)
      end
    end
  end

  def get(endpoint = nil)
    url = [@base_url, endpoint].compact.join('/')
    handle_response do
      Faraday.get(url, @query, @headers)
    end
  end

  private

  def handle_response
    response = yield
    return JSON.parse(response.body) if response.success?

    raise Error, "API Fail: #{response.status} - #{response.body}"
  rescue Faraday::Error => e
    raise Error, "Network Error: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "Parse Error: #{e.message}"
  end
end
