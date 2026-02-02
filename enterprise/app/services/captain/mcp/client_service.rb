require 'ipaddr'
require 'resolv'
require 'uri'

require 'mcp_client'
require 'captain/mcp/errors'

class Captain::Mcp::ClientService
  READ_TIMEOUT = 30
  RETRIES = 0
  RETRY_BACKOFF = 1

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

    MCPClient.connect(@mcp_server.url, **options, &method(:configure_faraday))
  end

  def configure_faraday(faraday)
    if ENV['MCP_SSL_VERIFY'].to_s == 'false'
      faraday.ssl.verify = false
    else
      faraday.ssl.verify = true
      ca_file = ENV.fetch('MCP_SSL_CA_FILE', nil)
      faraday.ssl.ca_file = ca_file if ca_file.present?
    end
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
    return result if result.is_a?(String)
    return result.to_json unless result.is_a?(Hash)

    content = result['content'] || result[:content] || []
    content.filter_map do |item|
      item = item.transform_keys(&:to_s) if item.is_a?(Hash)
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
