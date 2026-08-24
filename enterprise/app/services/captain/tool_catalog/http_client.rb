require 'erb'
require 'uri'

class Captain::ToolCatalog::HttpClient
  MAX_RESPONSE_SIZE = 256.kilobytes

  attr_reader :response_size

  def initialize(custom_tool:, operation:)
    @custom_tool = custom_tool
    @operation = operation
    @response_size = 0
  end

  def perform(arguments)
    url, body, headers = prepare_request(arguments.stringify_keys)
    response_body = fetch(url, body, headers)
    response_classifier.classify(response_body)
  rescue SafeFetch::HttpError => e
    raise http_error(e.message)
  rescue SafeFetch::FetchError => e
    raise fetch_error(e.message)
  rescue SafeFetch::FileTooLargeError
    raise Captain::ToolCatalog::ExecutionError.new('invalid_response', 'response_too_large')
  rescue SafeFetch::Error
    raise Captain::ToolCatalog::ExecutionError.new('upstream', 'provider_request_failed')
  end

  private

  attr_reader :custom_tool, :operation

  def prepare_request(arguments)
    url, body = build_request(arguments)
    validate_origin!(url)
    headers = authentication_headers
    headers['Content-Type'] = 'application/json' if body.present?
    [url, body, headers]
  end

  def response_classifier
    Captain::ToolCatalog::ResponseClassifier.new(
      provider_key: custom_tool.provider_key,
      source: operation.fetch('source')
    )
  end

  def build_request(arguments)
    request = operation.fetch('request')
    return graphql_request(request, arguments) if request.fetch('encoding') == 'graphql'

    rest_request(request, arguments)
  end

  def graphql_request(request, arguments)
    [request.fetch('url'), JSON.generate(query: operation.fetch('definition'), variables: arguments)]
  end

  def rest_request(request, arguments)
    parameters = request.fetch('parameters', [])
    ensure_required_arguments!(parameters, arguments)
    path_names = request.fetch('url').scan(/\{([a-zA-Z0-9_]+)\}/).flatten
    url = bind_path(request.fetch('url'), path_names, arguments)
    query_names = parameters.select { |parameter| parameter['in'] == 'query' }.pluck('name')
    query_names |= arguments.keys - path_names if request.fetch('method') == 'GET'
    url = append_query(url, arguments.slice(*query_names))

    body_arguments = arguments.except(*path_names, *query_names)
    body = JSON.generate(body_arguments) if request.fetch('method') == 'POST'
    [url, body]
  end

  def ensure_required_arguments!(parameters, arguments)
    missing = parameters.select { |parameter| parameter['required'] && !arguments.key?(parameter['name']) }.pluck('name')
    return if missing.empty?

    raise Captain::ToolCatalog::ExecutionError.new('validation', 'request_argument_missing')
  end

  def bind_path(url, path_names, arguments)
    path_names.reduce(url) do |result, name|
      value = arguments.fetch(name) do
        raise Captain::ToolCatalog::ExecutionError.new('validation', 'request_argument_missing')
      end
      raise Captain::ToolCatalog::ExecutionError.new('validation', 'invalid_path_argument') unless scalar?(value)

      result.gsub("{#{name}}", ERB::Util.url_encode(value.to_s))
    end
  end

  def append_query(url, arguments)
    return url if arguments.empty?

    pairs = arguments.flat_map do |key, value|
      values = value.is_a?(Array) ? value : [value]
      raise Captain::ToolCatalog::ExecutionError.new('validation', 'invalid_query_argument') unless values.all? { |item| scalar?(item) }

      values.map { |item| [key, item] }
    end
    uri = URI.parse(url)
    uri.query = [uri.query, URI.encode_www_form(pairs)].compact_blank.join('&')
    uri.to_s
  end

  def validate_origin!(url)
    uri = URI.parse(url)
    return if valid_origin?(uri)

    raise Captain::ToolCatalog::ExecutionError.new('validation', 'origin_not_allowed')
  rescue URI::InvalidURIError
    raise Captain::ToolCatalog::ExecutionError.new('validation', 'invalid_provider_url')
  end

  def valid_origin?(uri)
    return false unless uri.scheme == 'https' && uri.host.present? && uri.userinfo.blank? && uri.fragment.blank?

    origin = "#{uri.scheme}://#{uri.host}"
    origin += ":#{uri.port}" unless uri.port == 443
    custom_tool.definition.fetch('allowed_origins').include?(origin)
  end

  def authentication_headers
    hook = custom_tool.integration_hook
    token = hook&.access_token
    raise Captain::ToolCatalog::ExecutionError.new('authentication', 'provider_credential_missing') if token.blank?

    if custom_tool.provider_key == 'shopify'
      { 'X-Shopify-Access-Token' => token }
    else
      { 'Authorization' => "Bearer #{token}" }
    end
  end

  def fetch(url, body, headers)
    response_body = +''
    SafeFetch.fetch(
      url,
      method: operation.dig('request', 'method').downcase.to_sym,
      body: body,
      headers: headers,
      sensitive_headers: headers.keys,
      max_bytes: MAX_RESPONSE_SIZE,
      validate_content_type: false
    ) do |result|
      response_body = result.tempfile.read
    end
    @response_size += response_body.bytesize
    response_body
  end

  def http_error(message)
    status = message.to_s[/\A\d{3}/].to_i
    return Captain::ToolCatalog::ExecutionError.new('authentication', 'provider_authentication_failed') if status == 401
    return Captain::ToolCatalog::ExecutionError.new('authorization', 'provider_authorization_failed') if status == 403
    return Captain::ToolCatalog::ExecutionError.new('not_found', 'provider_resource_not_found') if status == 404
    return Captain::ToolCatalog::ExecutionError.new('rate_limit', 'provider_rate_limited') if status == 429
    return Captain::ToolCatalog::ExecutionError.new('timeout', 'provider_timeout') if [408, 504].include?(status)
    return Captain::ToolCatalog::ExecutionError.new('validation', 'provider_validation_failed') if [400, 409, 422].include?(status)

    Captain::ToolCatalog::ExecutionError.new('upstream', 'provider_request_failed')
  end

  def fetch_error(message)
    return Captain::ToolCatalog::ExecutionError.new('timeout', 'provider_timeout') if message.match?(/timed? ?out|timeout/i)

    Captain::ToolCatalog::ExecutionError.new('upstream', 'provider_unavailable')
  end

  def scalar?(value)
    value.is_a?(String) || value.is_a?(Numeric) || value == true || value == false
  end
end
