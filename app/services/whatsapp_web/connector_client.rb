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
    options = build_request_options(body: body, query: query, headers: headers)

    response = HTTParty.public_send(method, url, options)
    parsed_body = parse_response_body(response.body)
    return parsed_body if response.success?

    raise_request_error(response, parsed_body)
  rescue SocketError, Errno::ECONNREFUSED, Timeout::Error
    raise RequestError, 'Connector is unreachable'
  end

  def build_request_options(body:, query:, headers:)
    options = {
      timeout: DEFAULT_TIMEOUT,
      headers: default_headers.merge(headers)
    }
    options[:query] = query if query.present?

    return options if body.blank?

    options[:body] = body.to_json
    options[:headers]['Content-Type'] = 'application/json'
    options
  end

  def raise_request_error(response, parsed_body)
    error_message = extract_error_message(parsed_body)
    raise RequestError.new(
      "Connector request failed (#{response.code}): #{error_message}",
      status: response.code,
      response_body: parsed_body
    )
  end

  def default_headers
    headers = { 'Accept' => 'application/json' }
    headers['apikey'] = @api_key if @api_key.present?
    origin = evolution_origin_header
    headers['Origin'] = origin if origin.present?
    headers
  end

  def evolution_origin_header
    [
      ENV.fetch('WHATSAPP_WEB_EVOLUTION_ORIGIN', '').to_s.strip,
      ENV.fetch('FRONTEND_URL', '').to_s.strip,
      ENV.fetch('WIDGET_URL', '').to_s.strip
    ].each do |candidate|
      normalized = normalize_origin(candidate)
      return normalized if normalized.present?
    end

    ''
  end

  def normalize_origin(value)
    return '' if value.blank?

    parsed = URI.parse(value)
    return '' unless parsed.is_a?(URI::HTTP) && parsed.host.present?

    include_port = parsed.port.present? && parsed.default_port != parsed.port
    "#{parsed.scheme}://#{parsed.host}#{include_port ? ":#{parsed.port}" : ''}"
  rescue URI::InvalidURIError
    ''
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
    return parsed_body.to_s unless parsed_body.is_a?(Hash)
    return parsed_body['message'] if parsed_body['message'].present?

    nested_message = extract_nested_response_message(parsed_body['response'])
    return nested_message if nested_message.present?
    return parsed_body['error'] if parsed_body['error'].present?

    parsed_body.to_s
  end

  def extract_nested_response_message(response_payload)
    return nil unless response_payload.is_a?(Hash)

    message = response_payload['message']
    return message.join(', ') if message.is_a?(Array) && message.any?
    return message if message.present?

    response_payload['error']
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
