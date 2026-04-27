class SafeFetch::RequestOptions
  DEFAULTS = {
    method: :get,
    body: nil,
    max_bytes: nil,
    open_timeout: SafeFetch::DEFAULT_OPEN_TIMEOUT,
    read_timeout: SafeFetch::DEFAULT_READ_TIMEOUT,
    headers: nil,
    http_basic_authentication: nil,
    allowed_content_type_prefixes: SafeFetch::DEFAULT_ALLOWED_CONTENT_TYPE_PREFIXES,
    allowed_content_types: SafeFetch::DEFAULT_ALLOWED_CONTENT_TYPES,
    validate_content_type: true
  }.freeze

  attr_reader :allowed_content_type_prefixes, :allowed_content_types, :body, :headers,
              :http_basic_authentication, :method, :open_timeout, :read_timeout, :uri, :url

  def initialize(url:, **options)
    config = DEFAULTS.merge(options)
    @url = url
    @uri = parse_and_validate_url!(url)
    @method = normalize_method(config[:method])
    @body = config[:body]
    @max_bytes = config[:max_bytes]
    @open_timeout = config[:open_timeout]
    @read_timeout = config[:read_timeout]
    @headers = normalize_headers(config[:headers])
    @http_basic_authentication = config[:http_basic_authentication]
    @allowed_content_type_prefixes = Array(config[:allowed_content_type_prefixes])
    @allowed_content_types = Array(config[:allowed_content_types])
    @validate_content_type = config[:validate_content_type]
  end

  def effective_max_bytes
    @effective_max_bytes ||= @max_bytes || default_max_bytes
  end

  def filename
    @filename ||= File.basename(uri.path).presence || "download-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
  end

  def request_options
    {
      headers: headers,
      body: body,
      request_proc: request_proc,
      sensitive_headers: sensitive_headers,
      http_options: { open_timeout: open_timeout, read_timeout: read_timeout }
    }
  end

  def validate_content_type?
    @validate_content_type
  end

  private

  def default_max_bytes
    limit_mb = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', SafeFetch::DEFAULT_MAX_BYTES_FALLBACK_MB).to_i
    limit_mb = SafeFetch::DEFAULT_MAX_BYTES_FALLBACK_MB if limit_mb <= 0
    limit_mb.megabytes
  end

  def parse_and_validate_url!(value)
    parsed_uri = URI.parse(value)
    raise SafeFetch::InvalidUrlError, 'scheme must be http or https' unless parsed_uri.is_a?(URI::HTTP) || parsed_uri.is_a?(URI::HTTPS)
    raise SafeFetch::InvalidUrlError, 'missing host' if parsed_uri.host.blank?

    parsed_uri
  end

  def normalize_method(value)
    http_method = value.to_s.downcase.to_sym
    return http_method if SsrfFilter::VERB_MAP.key?(http_method)

    raise SafeFetch::UnsupportedMethodError, "unsupported method: #{value}"
  end

  def normalize_headers(value)
    value&.to_h
  end

  def request_proc
    proc do |request|
      credentials = http_basic_authentication.presence || basic_authentication_for(request.uri)
      request.basic_auth(*credentials) if credentials.present?
    end
  end

  def sensitive_headers
    SafeFetch::DEFAULT_SENSITIVE_HEADERS
  end

  def basic_authentication_for(request_uri)
    uri_basic_authentication(request_uri) || original_uri_basic_authentication(request_uri)
  end

  def original_uri_basic_authentication(request_uri)
    return unless same_origin?(request_uri, uri)

    uri_basic_authentication(uri)
  end

  def same_origin?(request_uri, other_uri)
    request_uri.scheme == other_uri.scheme && request_uri.hostname == other_uri.hostname && request_uri.port == other_uri.port
  end

  def uri_basic_authentication(value)
    return if value.user.blank?

    [
      URI.decode_uri_component(value.user),
      URI.decode_uri_component(value.password.to_s)
    ]
  end
end
