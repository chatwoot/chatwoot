require 'net/http'
require 'json'
require 'uri'

class Captain::Mcp::ClientService
  MCP_PROTOCOL_VERSION = '2024-11-05'.freeze
  CLIENT_NAME = 'chatwoot-captain'.freeze
  READ_TIMEOUT = 30
  OPEN_TIMEOUT = 10
  MAX_RESPONSE_SIZE = 1.megabyte

  PRIVATE_IP_RANGES = [
    IPAddr.new('127.0.0.0/8'),
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('192.168.0.0/16'),
    IPAddr.new('169.254.0.0/16'),
    IPAddr.new('::1'),
    IPAddr.new('fc00::/7'),
    IPAddr.new('fe80::/10')
  ].freeze

  attr_reader :mcp_server

  def initialize(mcp_server)
    @mcp_server = mcp_server
    @message_id = 0
    @session_endpoint = nil
  end

  def connect
    @mcp_server.update!(status: 'connecting')

    establish_session
    initialize_protocol

    @mcp_server.mark_connected!
    Result.success
  rescue StandardError => e
    Rails.logger.error("MCP connection error for #{@mcp_server.slug}: #{e.class} - #{e.message}")
    @mcp_server.mark_error!(e.message)
    Result.failure(e.message)
  end

  def disconnect
    @session_endpoint = nil
    @mcp_server.mark_disconnected!
  end

  def call_tool(tool_name, arguments = {})
    ensure_connected!

    response = send_request('tools/call', {
                              name: tool_name,
                              arguments: arguments
                            })

    raise Captain::Mcp::ToolExecutionError, response['error']['message'] if response['error']

    format_tool_result(response['result'])
  end

  def list_tools
    ensure_connected!

    response = send_request('tools/list', {})
    response.dig('result', 'tools') || []
  end

  private

  def establish_session
    uri = URI.parse(@mcp_server.url)
    check_private_ip!(uri.host)

    http = build_http_client(uri)
    request = Net::HTTP::Get.new(uri.request_uri)
    apply_authentication(request)
    request['Accept'] = 'text/event-stream'

    response = http.request(request)

    raise Captain::Mcp::ConnectionError, "Failed to establish SSE connection: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse_session_endpoint(response)
  end

  def parse_session_endpoint(response)
    @session_endpoint = @mcp_server.url

    if response['x-mcp-session-url']
      @session_endpoint = response['x-mcp-session-url']
    elsif response.body.present?
      response.body.each_line do |line|
        next unless line.start_with?('data:')

        data = begin
          JSON.parse(line.sub('data:', '').strip)
        rescue StandardError
          nil
        end
        @session_endpoint = data['endpoint'] if data&.dig('endpoint')
        break
      end
    end
  end

  def initialize_protocol
    response = send_request('initialize', {
                              protocolVersion: MCP_PROTOCOL_VERSION,
                              capabilities: {
                                tools: {}
                              },
                              clientInfo: {
                                name: CLIENT_NAME,
                                version: Chatwoot.config[:version] || '1.0.0'
                              }
                            })

    raise Captain::Mcp::ProtocolError, "Initialize failed: #{response['error']['message']}" if response['error']

    send_notification('notifications/initialized', {})
  end

  def ensure_connected!
    return if @session_endpoint.present?

    result = connect
    raise Captain::Mcp::ConnectionError, result.error unless result.success?
  end

  def send_request(method, params)
    uri = URI.parse(@session_endpoint)
    check_private_ip!(uri.host)

    http = build_http_client(uri)
    request = build_json_rpc_request(uri, method, params)

    response = http.request(request)

    raise Captain::Mcp::ProtocolError, "Request failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    validate_response_size!(response)
    JSON.parse(response.body)
  end

  def send_notification(method, params)
    uri = URI.parse(@session_endpoint)
    http = build_http_client(uri)

    request = Net::HTTP::Post.new(uri.request_uri)
    apply_authentication(request)
    request['Content-Type'] = 'application/json'
    request.body = {
      jsonrpc: '2.0',
      method: method,
      params: params
    }.to_json

    http.request(request)
  end

  def build_json_rpc_request(uri, method, params)
    request = Net::HTTP::Post.new(uri.request_uri)
    apply_authentication(request)
    request['Content-Type'] = 'application/json'
    request.body = {
      jsonrpc: '2.0',
      id: next_message_id,
      method: method,
      params: params
    }.to_json
    request
  end

  def build_http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = READ_TIMEOUT
    http.open_timeout = OPEN_TIMEOUT
    http.max_retries = 0
    http
  end

  def apply_authentication(request)
    headers = @mcp_server.build_auth_headers
    headers.each { |key, value| request[key] = value }
  end

  def check_private_ip!(hostname)
    ip_address = IPAddr.new(Resolv.getaddress(hostname))

    if PRIVATE_IP_RANGES.any? { |range| range.include?(ip_address) }
      raise Captain::Mcp::ConnectionError, 'Request blocked: hostname resolves to private IP address'
    end
  rescue Resolv::ResolvError, SocketError => e
    raise Captain::Mcp::ConnectionError, "DNS resolution failed: #{e.message}"
  end

  def validate_response_size!(response)
    content_length = response['content-length']&.to_i
    if content_length && content_length > MAX_RESPONSE_SIZE
      raise Captain::Mcp::ProtocolError, "Response size #{content_length} bytes exceeds maximum allowed #{MAX_RESPONSE_SIZE} bytes"
    end

    return unless response.body && response.body.bytesize > MAX_RESPONSE_SIZE

    raise Captain::Mcp::ProtocolError, "Response body size #{response.body.bytesize} bytes exceeds maximum allowed #{MAX_RESPONSE_SIZE} bytes"
  end

  def next_message_id
    @message_id += 1
  end

  def format_tool_result(result)
    content = result['content'] || []
    content.filter_map do |item|
      case item['type']
      when 'text'
        item['text']
      when 'image'
        "[Image: #{item['mimeType']}]"
      when 'resource'
        "[Resource: #{item.dig('resource', 'uri')}]"
      else
        item.to_json
      end
    end.join("\n")
  end

  class Result
    attr_reader :error

    def initialize(success:, error: nil)
      @success = success
      @error = error
    end

    def success?
      @success
    end

    def self.success
      new(success: true)
    end

    def self.failure(error)
      new(success: false, error: error)
    end
  end
end
