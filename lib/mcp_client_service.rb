# frozen_string_literal: true

require 'mcp_client'

# MCP Client Service - manages connections to MCP servers
# This service provides a centralized way to connect to and interact with
# Model Context Protocol servers, including the Mintlify documentation server.
class McpClientService
  include Singleton

  class ConfigurationError < StandardError; end
  class ConnectionError < StandardError; end
  class TimeoutError < StandardError; end

  attr_reader :clients, :connection_stats

  def initialize
    @clients = {}
    @connection_stats = {}
    @mutex = Mutex.new
    setup_clients
  end

  # Get or create a client for a specific server
  def client_for(server_name)
    @mutex.synchronize do
      return @clients[server_name] if @clients[server_name]

      Rails.logger.info("[McpClientService] Creating new client for #{server_name}")
      @clients[server_name] = create_client_for(server_name)
    end
  end

  # Execute a tool on a specific server with retry logic
  def call_tool(server_name, tool_name, arguments = {})
    validate_call_tool_params(server_name, tool_name, arguments)

    start_time = Time.current
    attempt = 0
    max_retries = 3

    begin
      attempt += 1
      client = client_for(server_name)
      raise ConnectionError, "No client available for #{server_name}" unless client

      Rails.logger.debug { "[McpClientService] Calling tool #{tool_name} on #{server_name} (attempt #{attempt})" }

      result = Timeout.timeout(60) do # 60 second timeout
        client.call_tool(tool_name, arguments)
      end

      record_successful_call(server_name, tool_name, Time.current - start_time)
      Rails.logger.debug { "[McpClientService] Tool call successful in #{(Time.current - start_time).round(2)}s" }
      result

    rescue StandardError => e
      record_failed_call(server_name, tool_name, e)

      if attempt < max_retries && should_retry?(e)
        Rails.logger.warn("[McpClientService] Retrying tool call #{tool_name} on #{server_name} (attempt #{attempt}/#{max_retries})")
        sleep(2 * attempt) # Simple backoff
        retry
      end

      Rails.logger.error("[McpClientService] Tool call failed after #{attempt} attempts: #{e.message}")
      handle_tool_call_error(e, server_name, tool_name)
    end
  end

  # List available tools for a server
  def list_tools(server_name)
    client = client_for(server_name)
    return [] unless client

    Rails.logger.debug { "[McpClientService] Listing tools for server: #{server_name}" }
    tools = client.list_tools || []

    Rails.logger.debug { "[McpClientService] Found #{tools.length} tools for #{server_name}" }
    tools

  rescue StandardError => e
    Rails.logger.error("[McpClientService] Error listing tools for #{server_name}: #{e.message}")
    record_failed_call(server_name, 'list_tools', e)
    []
  end

  # Get all available tools across all servers
  def all_tools
    tools = {}
    @clients.each_key do |server_name|
      tools[server_name] = list_tools(server_name)
    end
    tools
  end

  # Reconnect all clients (useful for development/testing)
  def reconnect_all!
    @mutex.synchronize do
      Rails.logger.info('[McpClientService] Reconnecting all MCP clients')
      close_all_connections
      @clients.clear
      @connection_stats.clear
      setup_clients
    end
  end

  # Get connection statistics
  def stats
    {
      clients: @clients.keys,
      connection_stats: @connection_stats.dup
    }
  end

  private

  def setup_clients
    # Set up Mintlify MCP server if enabled
    setup_mintlify_client if mintlify_enabled?
  end

  def setup_mintlify_client
    Rails.logger.info('[McpClientService] Setting up Mintlify MCP client')

    validate_mintlify_configuration!

    mcp_client = setup_mintlify_stdio_client

    raise ConnectionError, 'Failed to setup Mintlify client' unless mcp_client

    @clients['mintlify'] = mcp_client
    initialize_connection_stats('mintlify')
    Rails.logger.info('[McpClientService] Mintlify MCP client setup complete')

    # Test connection by listing tools (but don't fail if empty)
    begin
      tools = mcp_client.list_tools
      tool_names = extract_tool_names(tools)
      Rails.logger.info("[McpClientService] Found #{tools.length} tools: #{tool_names.join(', ')}")
    rescue StandardError => e
      Rails.logger.warn("[McpClientService] Could not list tools (but client may still work): #{e.message}")
    end

  rescue StandardError => e
    Rails.logger.error("[McpClientService] Failed to setup Mintlify client: #{e.message}")
    record_failed_call('mintlify', 'setup', e)
    raise e unless Rails.env.development?
  end

  def create_client_for(server_name)
    case server_name
    when 'mintlify'
      setup_mintlify_client
      @clients['mintlify']
    else
      raise ConfigurationError, "Unknown server: #{server_name}"
    end
  end

  def mintlify_enabled?
    # Always enabled - no configuration needed
    true
  end

  def validate_mintlify_configuration!
    home_dir = Dir.home || '/root'
    mcp_dir = "#{home_dir}/.mcp/#{mcp_server_id}"

    return if File.exist?(mcp_dir)

    Rails.logger.warn('[McpClientService] MCP server directory not found, attempting setup...')
    setup_mcp_server_if_needed

    return if File.exist?(mcp_dir)

    raise ConfigurationError, "MCP server not found at #{mcp_dir}. Run 'mcp add #{mcp_server_id}'"
  end

  def mintlify_command_array
    home_dir = Dir.home || '/root'
    command = "node #{home_dir}/.mcp/#{mcp_server_id}/src/index.js"
    command.split
  end

  def setup_mcp_server_if_needed
    home_dir = Dir.home || '/root'
    mcp_dir = "#{home_dir}/.mcp/#{mcp_server_id}"

    return if File.exist?(mcp_dir)

    Rails.logger.info('[McpClientService] Setting up Mintlify MCP server for the first time...')

    # Install MCP CLI and add the server with proper error handling
    install_success = system('npm install -g @mintlify/mcp 2>/dev/null')
    add_success = system("mcp add #{mcp_server_id} 2>/dev/null")

    return if install_success && add_success

    Rails.logger.error('[McpClientService] Failed to install or add MCP server')
    raise ConfigurationError, 'Failed to setup MCP server automatically'
  end

  def setup_mintlify_stdio_client
    command_array = mintlify_command_array
    Rails.logger.info("[McpClientService] Creating stdio client with command: #{command_array.inspect}")

    Timeout.timeout(30) do # 30 second connection timeout
      mcp_client = MCPClient.create_client(
        mcp_server_configs: [
          MCPClient.stdio_config(
            command: command_array,
            name: 'mintlify'
          )
        ]
      )

      Rails.logger.info('[McpClientService] Stdio transport successful')
      mcp_client
    end
  rescue StandardError => e
    Rails.logger.error("[McpClientService] Stdio transport failed: #{e.message}")
    raise ConnectionError, "Failed to connect to Mintlify MCP server: #{e.message}"
  end

  def should_retry?(error)
    return false if error.is_a?(ConfigurationError)
    return false if error.is_a?(ArgumentError)

    true
  end

  def validate_call_tool_params(server_name, tool_name, arguments)
    raise ArgumentError, 'server_name cannot be blank' if server_name.blank?
    raise ArgumentError, 'tool_name cannot be blank' if tool_name.blank?
    raise ArgumentError, 'arguments must be a Hash' unless arguments.is_a?(Hash)
  end

  def extract_tool_names(tools)
    tools.filter_map do |tool|
      case tool
      when Hash
        tool['name']
      else
        tool.respond_to?(:name) ? tool.name : tool.to_s
      end
    end
  end

  def initialize_connection_stats(server_name)
    @connection_stats[server_name] = {
      total_calls: 0,
      successful_calls: 0,
      failed_calls: 0,
      average_response_time: 0.0,
      last_error: nil,
      created_at: Time.current
    }
  end

  def record_successful_call(server_name, _tool_name, response_time)
    stats = @connection_stats[server_name] ||= initialize_connection_stats(server_name)
    stats[:total_calls] += 1
    stats[:successful_calls] += 1
    stats[:average_response_time] = ((stats[:average_response_time] * (stats[:total_calls] - 1)) + response_time) / stats[:total_calls]
  end

  def record_failed_call(server_name, _tool_name, error)
    stats = @connection_stats[server_name] ||= initialize_connection_stats(server_name)
    stats[:total_calls] += 1
    stats[:failed_calls] += 1
    stats[:last_error] = error.message
  end

  def handle_tool_call_error(error, server_name, tool_name)
    case error
    when Timeout::Error
      "Tool call timed out: could not #{tool_name} on #{server_name}"
    when ConnectionError
      "Connection failed: could not #{tool_name} on #{server_name}"
    when ConfigurationError
      "Configuration error: could not #{tool_name} on #{server_name}"
    else
      "Error occurred: could not #{tool_name} on #{server_name} (#{error.message})"
    end
  end

  def close_all_connections
    @clients.each_value do |client|
      client.close if client.respond_to?(:close)
    rescue StandardError => e
      Rails.logger.warn("[McpClientService] Error closing client connection: #{e.message}")
    end
  end

  def mcp_server_id
    ENV.fetch('MCP_SERVER_ID') do
      raise ConfigurationError, 'MCP_SERVER_ID environment variable is required. Please set it to your MCP server identifier.'
    end
  end
end
