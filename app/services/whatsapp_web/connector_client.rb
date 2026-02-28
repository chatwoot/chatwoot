require 'json'
require 'uri'
require 'httparty'

class WhatsappWeb::ConnectorClient
  class RequestError < StandardError
    attr_reader :status, :response_body

    def initialize(message, status: nil, response_body: nil)
      super(message)
      @status = status
      @response_body = response_body
    end
  end

  DEFAULT_TIMEOUT = 20

  def initialize(
    base_url:,
    base_path: nil,
    api_key: nil
  )
    @base_url = normalize_base_url(base_url)
    @base_path = normalize_base_path(base_path)
    @api_key = api_key.to_s.strip
  end

  def get(path, query: nil, headers: {})
    request(:get, path, query: query, headers: headers)
  end

  def post(path, body: nil, query: nil, headers: {})
    request(:post, path, body: body, query: query, headers: headers)
  end

  def put(path, body: nil, query: nil, headers: {})
    request(:put, path, body: body, query: query, headers: headers)
  end

  def delete(path, query: nil, headers: {})
    request(:delete, path, query: query, headers: headers)
  end

  private

  def request(method, path, body: nil, query: nil, headers: {})
    url = build_url(path)
    options = {
      timeout: DEFAULT_TIMEOUT,
      headers: default_headers.merge(headers)
    }
    options[:query] = query if query.present?

    if body.present?
      options[:body] = body.to_json
      options[:headers]['Content-Type'] = 'application/json'
    end

    response = HTTParty.public_send(method, url, options)
    parsed_body = parse_response_body(response.body)
    return parsed_body if response.success?

    error_message = extract_error_message(parsed_body)
    raise RequestError.new(
      "Connector request failed (#{response.code}): #{error_message}",
      status: response.code,
      response_body: parsed_body
    )
  rescue SocketError, Errno::ECONNREFUSED, Timeout::Error, Net::OpenTimeout, Net::ReadTimeout
    raise RequestError, 'Connector is unreachable'
  end

  def default_headers
    headers = { 'Accept' => 'application/json' }
    headers['apikey'] = @api_key if @api_key.present?
    headers
  end

  def build_url(path)
    relative_path = path.to_s.strip
    relative_path = "/#{relative_path}" unless relative_path.start_with?('/')
    "#{@base_url}#{@base_path}#{relative_path}"
  end

  def parse_response_body(raw_body)
    return {} if raw_body.blank?

    JSON.parse(raw_body)
  rescue JSON::ParserError
    { 'message' => raw_body.to_s }
  end

  def extract_error_message(parsed_body)
    return parsed_body['message'] if parsed_body.is_a?(Hash) && parsed_body['message'].present?

    if parsed_body.is_a?(Hash) && parsed_body['response'].is_a?(Hash)
      response = parsed_body['response']
      return response['message'].join(', ') if response['message'].is_a?(Array) && response['message'].any?
      return response['message'] if response['message'].present?
      return response['error'] if response['error'].present?
    end

    return parsed_body['error'] if parsed_body.is_a?(Hash) && parsed_body['error'].present?

    parsed_body.to_s
  end

  def normalize_base_url(url)
    parsed = URI.parse(url.to_s.strip)
    raise RequestError, 'evolution_base_url must be a valid http/https URL' unless parsed.is_a?(URI::HTTP) && parsed.host.present?

    include_port = parsed.port.present? && parsed.default_port != parsed.port
    "#{parsed.scheme}://#{parsed.host}#{include_port ? ":#{parsed.port}" : ''}".chomp('/')
  rescue URI::InvalidURIError
    raise RequestError, 'evolution_base_url must be a valid URL'
  end

  def normalize_base_path(path)
    normalized = path.to_s.strip
    return '' if normalized.blank?

    normalized = "/#{normalized}" unless normalized.start_with?('/')
    normalized.chomp('/')
  end
end
