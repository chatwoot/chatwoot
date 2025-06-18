# frozen_string_literal: true

require 'singleton'
require 'timeout'
require_relative 'mcp/clients/mintlify_client'
require_relative 'mcp/clients/acme_mintlify_client'

# MCP Client Service
# Main service that manages MCP client connections using a structured approach
class McpClientService
  include Singleton

  class ClientNotFoundError < StandardError; end

  attr_reader :clients

  def initialize
    @clients = {}
    # Don't auto-setup in initializer to avoid issues with Rails loading
  end

  # Initialize both servers with default configurations
  def initialize_default_servers!
    Rails.logger.info('[McpClientService] Initializing default MCP servers...')
    start_time = Time.current

    begin
      initialize_mintlify_server
      initialize_acme_server

      duration = Time.current - start_time
      Rails.logger.info("[McpClientService] All default servers initialized successfully in #{duration.round(2)}s")

      log_connection_status

    rescue StandardError => e
      Rails.logger.error("[McpClientService] Failed to initialize some servers: #{e.message}")
      Rails.logger.debug { "[McpClientService] Backtrace: #{e.backtrace.first(3).join(', ')}" }
    end
  end

  # Get or create a client for a specific type
  def client_for(type, config = {})
    type = type.to_s.downcase

    return @clients[type] if @clients[type]&.connected?

    Rails.logger.debug { "[McpClientService] Creating client for #{type}" }
    connection_start = Time.current

    begin
      # Create and connect the client with provided config
      # Each client has its own default configuration
      client = create_client(type, config)
      client.connect!

      @clients[type] = client

      duration = Time.current - connection_start
      Rails.logger.info("[McpClientService] #{type} client ready in #{duration.round(2)}s")

      client
    rescue StandardError => e
      Rails.logger.error("[McpClientService] Failed to create #{type} client: #{e.message}")
      raise
    end
  end

  # Call a tool on a specific client
  def call_tool(type, tool_name, arguments = {})
    client = client_for(type)
    client.call_tool(tool_name, arguments)
  end

  # List available tools for a client
  def list_tools(type)
    client = client_for(type)
    client.list_tools
  end

  # Check if a client is connected
  def connected?(type)
    client = @clients[type.to_s.downcase]
    client&.connected? || false
  end

  # Get available client types
  def available_types
    %w[mintlify acme_mintlify]
  end

  # Quick setup for a client type
  def setup_client(type)
    case type.to_s.downcase
    when 'mintlify'
      client = Mcp::Clients::MintlifyClient.new
      client.setup_if_needed!
      true
    when 'acme_mintlify'
      client = Mcp::Clients::AcmeMintlifyClient.new
      client.setup_if_needed!
      true
    else
      false
    end
  end

  private

  def initialize_mintlify_server
    connection_start = Time.current

    begin
      config = {
        server_id: 'chatwoot-447c5a93',
        auto_setup: true,
        test_on_connect: true
      }

      client = create_client('mintlify', config)
      client.connect!
      @clients['mintlify'] = client
      duration = Time.current - connection_start

      Rails.logger.info("[McpClientService] Mintlify server connected successfully in #{duration.round(2)}s")
      tools = client.list_tools
      Rails.logger.info("[McpClientService] Mintlify server tools: #{tools.length} tools available")

    rescue StandardError => e
      Rails.logger.warn("[McpClientService] Mintlify server initialization failed: #{e.message}")
      Rails.logger.debug { "[McpClientService] Mintlify error backtrace: #{e.backtrace.first(3).join(', ')}" }
    end
  end

  def initialize_acme_server
    connection_start = Time.current

    begin
      config = {
        server_id: 'acme-d0cb791b',
        auto_setup: true,
        test_on_connect: true,
        auth: {
          config: { 'api_access_token' => get_acme_api_token }
        }
      }

      client = create_client('acme_mintlify', config)
      client.connect!
      @clients['acme_mintlify'] = client
      duration = Time.current - connection_start

      Rails.logger.info("[McpClientService] Acme server connected successfully in #{duration.round(2)}s")
      tools = client.list_tools
      Rails.logger.info("[McpClientService] Acme server tools: #{tools.length} tools available")

    rescue StandardError => e
      Rails.logger.warn("[McpClientService] Acme server initialization failed: #{e.message}")
      Rails.logger.debug { "[McpClientService] Acme error backtrace: #{e.backtrace.first(3).join(', ')}" }
    end
  end

  def get_acme_api_token
    # TODO: Update this to use the actual API token, or figure out a better way to get the token
    ENV['ACME_MINTLIFY_API_TOKEN'] || 'demo_token'
  end

  def log_connection_status
    Rails.logger.info('[McpClientService] Connection Status Summary:')

    available_types.each do |type|
      status = connected?(type) ? 'Connected' : 'Disconnected'
      Rails.logger.info("[McpClientService]   #{type}: #{status}")
    end

    Rails.logger.info("[McpClientService] MCP setup complete - #{@clients.keys.size} clients ready")
  end

  def create_client(type, config)
    case type.to_s.downcase
    when 'mintlify'
      Mcp::Clients::MintlifyClient.new(config)
    when 'acme_mintlify'
      Mcp::Clients::AcmeMintlifyClient.new(config)
    else
      raise ClientNotFoundError, "Unknown client type: #{type}"
    end
  end
end
