# frozen_string_literal: true

# Fast MCP - A Ruby Implementation of the Model Context Protocol (Server-side)
# https://modelcontextprotocol.io/introduction

# Define the MCP module
module FastMcp
  class << self
    attr_accessor :server
  end
end

# Require the core components
require_relative 'mcp/tool'
require_relative 'mcp/server'
require_relative 'mcp/resource'
require_relative 'mcp/railtie' if defined?(Rails::Railtie)

# Load generators if Rails is available
require_relative 'generators/fast_mcp/install/install_generator' if defined?(Rails::Generators)

# Require all transport files
require_relative 'mcp/transports/base_transport'
Dir[File.join(File.dirname(__FILE__), 'mcp/transports', '*.rb')].each do |file|
  require file
end

# Version information
require_relative 'mcp/version'

# Convenience method to create a Rack middleware
module FastMcp
  # Create a Rack middleware for the MCP server
  # @param app [#call] The Rack application
  # @param options [Hash] Options for the middleware
  # @option options [String] :name The name of the server
  # @option options [String] :version The version of the server
  # @option options [String] :path_prefix The path prefix for the MCP endpoints
  # @option options [String] :messages_route The route for the messages endpoint
  # @option options [String] :sse_route The route for the SSE endpoint
  # @option options [Logger] :logger The logger to use
  # @option options [Array<String,Regexp>] :allowed_origins List of allowed origins for DNS rebinding protection
  # @yield [server] A block to configure the server
  # @yieldparam server [FastMcp::Server] The server to configure
  # @return [#call] The Rack middleware
  def self.rack_middleware(app, options = {})
    name = options.delete(:name) || 'mcp-server'
    version = options.delete(:version) || '1.0.0'
    logger = options.delete(:logger) || Logger.new

    server = FastMcp::Server.new(name: name, version: version, logger: logger)
    yield server if block_given?

    # Store the server in the Sinatra settings if available
    app.settings.set(:mcp_server, server) if app.respond_to?(:settings) && app.settings.respond_to?(:mcp_server=)

    # Store the server in the FastMcp module
    self.server = server

    server.start_rack(app, options)
  end

  # Create a Rack middleware for the MCP server with authentication
  # @param app [#call] The Rack application
  # @param options [Hash] Options for the middleware
  # @option options [String] :name The name of the server
  # @option options [String] :version The version of the server
  # @option options [String] :auth_token The authentication token
  # @option options [Array<String,Regexp>] :allowed_origins List of allowed origins for DNS rebinding protection
  # @yield [server] A block to configure the server
  # @yieldparam server [FastMcp::Server] The server to configure
  # @return [#call] The Rack middleware
  def self.authenticated_rack_middleware(app, options = {})
    name = options.delete(:name) || 'mcp-server'
    version = options.delete(:version) || '1.0.0'
    logger = options.delete(:logger) || Logger.new

    server = FastMcp::Server.new(name: name, version: version, logger: logger)
    yield server if block_given?

    # Store the server in the FastMcp module
    self.server = server

    server.start_authenticated_rack(app, options)
  end

  # Register a tool with the MCP server
  # @param tool [FastMcp::Tool] The tool to register
  # @return [FastMcp::Tool] The registered tool
  def self.register_tool(tool)
    self.server ||= FastMcp::Server.new(name: 'mcp-server', version: '1.0.0')
    self.server.register_tool(tool)
  end

  # Register multiple tools at once
  # @param tools [Array<FastMcp::Tool>] The tools to register
  # @return [Array<FastMcp::Tool>] The registered tools
  def self.register_tools(*tools)
    self.server ||= FastMcp::Server.new(name: 'mcp-server', version: '1.0.0')
    self.server.register_tools(*tools)
  end

  # Register a resource with the MCP server
  # @param resource [FastMcp::Resource] The resource to register
  # @return [FastMcp::Resource] The registered resource
  def self.register_resource(resource)
    self.server ||= FastMcp::Server.new(name: 'mcp-server', version: '1.0.0')
    self.server.register_resource(resource)
  end

  # Register multiple resources at once
  # @param resources [Array<FastMcp::Resource>] The resources to register
  # @return [Array<FastMcp::Resource>] The registered resources
  def self.register_resources(*resources)
    self.server ||= FastMcp::Server.new(name: 'mcp-server', version: '1.0.0')
    self.server.register_resources(*resources)
  end

  # Mount the MCP middleware in a Rails application
  # @param app [Rails::Application] The Rails application
  # @param options [Hash] Options for the middleware
  # @option options [String] :name The name of the server
  # @option options [String] :version The version of the server
  # @option options [String] :path_prefix The path prefix for the MCP endpoints
  # @option options [String] :messages_route The route for the messages endpoint
  # @option options [String] :sse_route The route for the SSE endpoint
  # @option options [Logger] :logger The logger to use
  # @option options [Boolean] :authenticate Whether to use authentication
  # @option options [String] :auth_token The authentication token
  # @option options [Array<String,Regexp>] :allowed_origins List of allowed origins for DNS rebinding protection
  # @yield [server] A block to configure the server
  # @yieldparam server [FastMcp::Server] The server to configure
  # @return [#call] The Rack middleware
  def self.mount_in_rails(app, options = {})
    # Default options
    name = options.delete(:name) || app.class.module_parent_name.underscore.dasherize
    version = options.delete(:version) || '1.0.0'
    logger = options[:logger] || Rails.logger
    path_prefix = options.delete(:path_prefix) || '/mcp'
    messages_route = options.delete(:messages_route) || 'messages'
    sse_route = options.delete(:sse_route) || 'sse'
    authenticate = options.delete(:authenticate) || false
    allowed_origins = options[:allowed_origins] || default_rails_allowed_origins(app)
    allowed_ips = options[:allowed_ips] || FastMcp::Transports::RackTransport::DEFAULT_ALLOWED_IPS

    options[:localhost_only] = Rails.env.local? if options[:localhost_only].nil?
    options[:allowed_ips] = allowed_ips
    options[:logger] = logger
    options[:allowed_origins] = allowed_origins

    # Create or get the server
    self.server = FastMcp::Server.new(name: name, version: version, logger: logger)
    yield self.server if block_given?

    # Choose the right middleware based on authentication
    self.server.transport_klass = if authenticate
                                    FastMcp::Transports::AuthenticatedRackTransport
                                  else
                                    FastMcp::Transports::RackTransport
                                  end

    # Insert the middleware in the Rails middleware stack
    app.middleware.use(
      self.server.transport_klass,
      self.server,
      options.merge(path_prefix: path_prefix, messages_route: messages_route, sse_route: sse_route)
    )
  end

  def self.default_rails_allowed_origins(rail_app)
    hosts = rail_app.config.hosts

    hosts.map do |host|
      if host.is_a?(String) && host.start_with?('.')
        # Convert .domain to domain and *.domain
        host_without_dot = host[1..]
        [host_without_dot, Regexp.new(".*\.#{host_without_dot}")] # rubocop:disable Style/RedundantStringEscape
      else
        host
      end
    end.flatten.compact
  end

  # Notify the server that a resource has been updated
  # @param uri [String] The URI of the resource
  def self.notify_resource_updated(uri)
    self.server.notify_resource_updated(uri)
  end
end
