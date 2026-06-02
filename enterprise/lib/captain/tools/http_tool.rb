require 'agents'

class Captain::Tools::HttpTool < Agents::Tool
  def initialize(assistant, custom_tool)
    @assistant = assistant
    @custom_tool = custom_tool
    super()
  end

  def active?
    @custom_tool.enabled?
  end

  def perform(tool_context, **params)
    url = @custom_tool.build_request_url(params)
    body = @custom_tool.build_request_body(params)

    response = execute_http_request(url, body, tool_context)
    @custom_tool.format_response(response.body)
  rescue StandardError => e
    Rails.logger.error("HttpTool execution error for #{@custom_tool.slug}: #{e.class} - #{e.message}")
    'An error occurred while executing the request'
  end

  private

  PRIVATE_IP_RANGES = [
    IPAddr.new('127.0.0.0/8'),    # IPv4 Loopback
    IPAddr.new('10.0.0.0/8'),     # IPv4 Private network
    IPAddr.new('172.16.0.0/12'),  # IPv4 Private network
    IPAddr.new('192.168.0.0/16'), # IPv4 Private network
    IPAddr.new('169.254.0.0/16'), # IPv4 Link-local
    IPAddr.new('::1'),            # IPv6 Loopback
    IPAddr.new('fc00::/7'),       # IPv6 Unique local addresses
    IPAddr.new('fe80::/10')       # IPv6 Link-local
  ].freeze

  # Limit response size to prevent memory exhaustion and match LLM token limits
  # 1MB of text ≈ 250K tokens, which exceeds most LLM context windows
  MAX_RESPONSE_SIZE = 1.megabyte

  def execute_http_request(url, body, tool_context)
    uri = URI.parse(url)

    # Check if resolved IP is private
    check_private_ip!(uri.host)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 30
    http.open_timeout = 10
    http.max_retries = 0 # Disable redirects

    request = build_http_request(uri, body)
    apply_authentication(request)
    apply_metadata_headers(request, tool_context)

    response = http.request(request)

    raise "HTTP request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    validate_response!(response)

    response
  end

  def check_private_ip!(hostname)
    ip_address = IPAddr.new(Resolv.getaddress(hostname))

    raise 'Request blocked: hostname resolves to private IP address' if PRIVATE_IP_RANGES.any? { |range| range.include?(ip_address) }
  rescue Resolv::ResolvError, SocketError => e
    raise "DNS resolution failed: #{e.message}"
  end

  def validate_response!(response)
    content_length = response['content-length']&.to_i
    if content_length && content_length > MAX_RESPONSE_SIZE
      raise "Response size #{content_length} bytes exceeds maximum allowed #{MAX_RESPONSE_SIZE} bytes"
    end

    return unless response.body && response.body.bytesize > MAX_RESPONSE_SIZE

    raise "Response body size #{response.body.bytesize} bytes exceeds maximum allowed #{MAX_RESPONSE_SIZE} bytes"
  end

  def build_http_request(uri, body)
    if @custom_tool.http_method == 'POST'
      request = Net::HTTP::Post.new(uri.request_uri)
      if body
        request.body = body
        request['Content-Type'] = 'application/json'
      end
    else
      request = Net::HTTP::Get.new(uri.request_uri)
    end
    request
  end

  def apply_authentication(request)
    headers = @custom_tool.build_auth_headers
    headers.each { |key, value| request[key] = value }

    credentials = @custom_tool.build_basic_auth_credentials
    request.basic_auth(*credentials) if credentials
  end

  def apply_metadata_headers(request, tool_context)
    state = tool_context&.state || {}
    metadata_headers = @custom_tool.build_metadata_headers(state)
    metadata_headers.each { |key, value| request[key] = value }
  end
end
