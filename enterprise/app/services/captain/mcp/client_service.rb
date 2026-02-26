require 'ipaddr'
require 'resolv'
require 'uri'

require 'mcp_client'
require 'captain/mcp/errors'

class Captain::Mcp::ClientService
  READ_TIMEOUT = 30
  RETRIES = 0
  RETRY_BACKOFF = 1
  MAX_RESPONSE_SIZE = 1.megabyte

  PRIVATE_IP_RANGES = [
    IPAddr.new('0.0.0.0/8'),       # Current network
    IPAddr.new('127.0.0.0/8'),     # Loopback
    IPAddr.new('10.0.0.0/8'),      # Private class A
    IPAddr.new('172.16.0.0/12'),   # Private class B
    IPAddr.new('192.168.0.0/16'),  # Private class C
    IPAddr.new('169.254.0.0/16'), # Link-local
    IPAddr.new('100.64.0.0/10'),  # Carrier-grade NAT (RFC 6598)
    IPAddr.new('::1/128'),         # IPv6 loopback
    IPAddr.new('fc00::/7'),        # IPv6 unique local
    IPAddr.new('fe80::/10'),       # IPv6 link-local
    IPAddr.new('::ffff:0:0/96')   # IPv4-mapped IPv6 addresses
  ].freeze

  attr_reader :mcp_server

  def initialize(mcp_server)
    @mcp_server = mcp_server
    @client = nil
  end

  def connect
    @mcp_server.update!(status: 'connecting')
    ensure_public_host!
    @client = build_client
    @mcp_server.mark_connected!
    Result.success
  rescue MCPClient::Errors::MCPError, StandardError => e
    handle_connection_error(e)
  end

  def disconnect
    @client&.cleanup
    @client = nil
    @mcp_server.mark_disconnected!
  end

  def call_tool(tool_name, arguments = {})
    client = ensure_client!
    result = client.call_tool(tool_name, arguments)
    format_tool_result(result)
  rescue MCPClient::Errors::ToolCallError => e
    raise Captain::Mcp::ToolExecutionError, e.message
  rescue MCPClient::Errors::ConnectionError, MCPClient::Errors::TransportError => e
    raise Captain::Mcp::ConnectionError, e.message
  rescue MCPClient::Errors::MCPError => e
    raise Captain::Mcp::Error, e.message
  end

  def list_tools
    client = ensure_client!
    tools = client.list_tools(cache: false)
    tools.map { |tool| serialize_tool(tool) }
  rescue MCPClient::Errors::ConnectionError, MCPClient::Errors::TransportError => e
    raise Captain::Mcp::ConnectionError, e.message
  rescue MCPClient::Errors::MCPError => e
    raise Captain::Mcp::Error, e.message
  end

  private

  def ensure_client!
    return @client if @client

    result = connect
    raise Captain::Mcp::ConnectionError, result.error unless result.success?

    @client
  end

  def build_client
    headers = @mcp_server.build_auth_headers
    auth_config = @mcp_server.auth_config || {}
    options = {
      headers: headers,
      read_timeout: READ_TIMEOUT,
      retries: RETRIES,
      retry_backoff: RETRY_BACKOFF,
      logger: Rails.logger
    }

    transport = auth_config['transport'] || ENV.fetch('MCP_TRANSPORT', nil)
    options[:transport] = transport.to_sym if transport.present?

    endpoint = auth_config['rpc_endpoint'] || ENV.fetch('MCP_RPC_ENDPOINT', nil)
    options[:endpoint] = endpoint if endpoint.present?

    MCPClient.connect(@mcp_server.url, **options) { |faraday| configure_faraday(faraday) }
  end

  def configure_faraday(faraday)
    faraday.ssl.verify = ENV['MCP_SSL_VERIFY'].to_s != 'false'
    ca_file = ENV.fetch('MCP_SSL_CA_FILE', nil)
    faraday.ssl.ca_file = ca_file if ca_file.present? && faraday.ssl.verify
  end

  def ensure_public_host!
    uri = URI.parse(@mcp_server.url)
    return if uri.host.blank?

    check_private_ip!(uri.host)
  end

  def check_private_ip!(hostname)
    ip_address = IPAddr.new(Resolv.getaddress(hostname))

    if PRIVATE_IP_RANGES.any? { |range| range.include?(ip_address) }
      raise Captain::Mcp::ConnectionError, 'Request blocked: hostname resolves to private IP address'
    end
  rescue Resolv::ResolvError, SocketError => e
    raise Captain::Mcp::ConnectionError, "DNS resolution failed: #{e.message}"
  end

  def serialize_tool(tool)
    {
      'name' => tool.name,
      'description' => tool.description,
      'inputSchema' => tool.schema,
      'outputSchema' => tool.output_schema,
      'annotations' => tool.annotations
    }.compact
  end

  def format_tool_result(result)
    formatted = format_tool_content(result)
    truncate_response(formatted)
  end

  def format_tool_content(result)
    return result if result.is_a?(String)
    return result.to_json unless result.is_a?(Hash)

    content = result['content'] || result[:content] || []
    content.filter_map { |item| format_content_item(item) }.join("\n")
  end

  def truncate_response(text)
    return text if text.bytesize <= MAX_RESPONSE_SIZE

    Rails.logger.warn("MCP response truncated from #{text.bytesize} bytes to #{MAX_RESPONSE_SIZE} bytes for #{@mcp_server.slug}")
    text.truncate_bytes(MAX_RESPONSE_SIZE, omission: '')
  end

  def format_content_item(item)
    item = item.transform_keys(&:to_s) if item.is_a?(Hash)
    case item['type']
    when 'text' then item['text']
    when 'image' then "[Image: #{item['mimeType']}]"
    when 'resource' then "[Resource: #{item.dig('resource', 'uri')}]"
    else item.to_json
    end
  end

  def handle_connection_error(error)
    Rails.logger.error("MCP connection error for #{@mcp_server.slug}: #{error.class} - #{error.message}")
    @mcp_server.mark_error!(error.message)
    Result.failure(error.message)
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
