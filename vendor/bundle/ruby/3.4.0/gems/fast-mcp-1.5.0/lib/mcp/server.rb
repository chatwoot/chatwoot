# frozen_string_literal: true

require 'json'
require 'logger'
require 'securerandom'
require 'base64'
require_relative 'transports/stdio_transport'
require_relative 'transports/rack_transport'
require_relative 'transports/authenticated_rack_transport'
require_relative 'logger'
require_relative 'server_filtering'

module FastMcp
  class Server
    include ServerFiltering

    attr_reader :name, :version, :tools, :resources, :capabilities

    DEFAULT_CAPABILITIES = {
      resources: {
        subscribe: true,
        listChanged: true
      },
      tools: {
        listChanged: true
      }
    }.freeze

    def initialize(name:, version:, logger: FastMcp::Logger.new, capabilities: {})
      @name = name
      @version = version
      @tools = {}
      @resources = []
      @resource_subscriptions = {}
      @logger = logger
      @request_id = 0
      @transport_klass = nil
      @transport = nil
      @capabilities = DEFAULT_CAPABILITIES.dup
      @tool_filters = []
      @resource_filters = []

      # Merge with provided capabilities
      @capabilities.merge!(capabilities) if capabilities.is_a?(Hash)
    end
    attr_accessor :transport, :transport_klass, :logger

    # Register multiple tools at once
    # @param tools [Array<Tool>] Tools to register
    def register_tools(*tools)
      tools.each do |tool|
        register_tool(tool)
      end
    end

    # Register a tool with the server
    def register_tool(tool)
      @tools[tool.tool_name] = tool
      @logger.debug("Registered tool: #{tool.tool_name}")
      tool.server = self
    end

    # Register multiple resources at once
    # @param resources [Array<Resource>] Resources to register
    def register_resources(*resources)
      resources.each do |resource|
        register_resource(resource)
      end
    end

    # Register a resource with the server
    def register_resource(resource)
      @resources << resource

      @logger.debug("Registered resource: #{resource.resource_name} (#{resource.uri})")
      resource.server = self
      # Notify subscribers about the list change
      notify_resource_list_changed if @transport

      resource
    end

    # Remove a resource from the server
    def remove_resource(uri)
      resource = @resources.find { |r| r.uri == uri }

      if resource
        @resources.delete(resource)
        @logger.debug("Removed resource: #{resource.name} (#{uri})")

        # Notify subscribers about the list change
        notify_resource_list_changed if @transport

        true
      else
        false
      end
    end

    # Start the server using stdio transport
    def start
      @logger.transport = :stdio
      @logger.info("Starting MCP server: #{@name} v#{@version}")
      @logger.info("Available tools: #{@tools.keys.join(', ')}")
      @logger.info("Available resources: #{@resources.map(&:resource_name).join(', ')}")

      # Use STDIO transport by default
      @transport_klass = FastMcp::Transports::StdioTransport
      @transport = @transport_klass.new(self, logger: @logger)
      @transport.start
    end

    # Start the server as a Rack middleware
    def start_rack(app, options = {})
      @logger.info("Starting MCP server as Rack middleware: #{@name} v#{@version}")
      @logger.info("Available tools: #{@tools.keys.join(', ')}")
      @logger.info("Available resources: #{@resources.map(&:resource_name).join(', ')}")

      # Use Rack transport
      transport_klass = FastMcp::Transports::RackTransport
      @transport = transport_klass.new(app, self, options.merge(logger: @logger))
      @transport.start

      # Return the transport as middleware
      @transport
    end

    def start_authenticated_rack(app, options = {})
      @logger.info("Starting MCP server as Authenticated Rack middleware: #{@name} v#{@version}")
      @logger.info("Available tools: #{@tools.keys.join(', ')}")
      @logger.info("Available resources: #{@resources.map(&:resource_name).join(', ')}")

      # Use Rack transport
      transport_klass = FastMcp::Transports::AuthenticatedRackTransport
      @transport = transport_klass.new(app, self, options.merge(logger: @logger))
      @transport.start

      # Return the transport as middleware
      @transport
    end

    # Handle a JSON-RPC request and return the response as a JSON string
    def handle_json_request(request, headers: {})
      request_str = request.is_a?(String) ? request : JSON.generate(request)

      handle_request(request_str, headers: headers)
    end

    # Handle incoming JSON-RPC request
    def handle_request(json_str, headers: {}) # rubocop:disable Metrics/MethodLength
      begin
        request = JSON.parse(json_str)
      rescue JSON::ParserError, TypeError
        return send_error(-32_600, 'Invalid Request', nil)
      end

      @logger.debug("Received request: #{request.inspect}")

      method = request['method']
      params = request['params'] || {}
      id = request['id']

      # Check if it's a valid JSON-RPC 2.0 request
      return send_error(-32_600, 'Invalid Request', id) unless request['jsonrpc'] == '2.0'

      case method
      when 'ping'
        send_result({}, id)
      when 'initialize'
        handle_initialize(params, id)
      when 'notifications/initialized'
        handle_initialized_notification
      when 'tools/list'
        handle_tools_list(id)
      when 'tools/call'
        handle_tools_call(params, headers, id)
      when 'resources/list'
        handle_resources_list(id)
      when 'resources/templates/list'
        handle_resources_templates_list(id)
      when 'resources/read'
        handle_resources_read(params, id)
      when 'resources/subscribe'
        handle_resources_subscribe(params, id)
      when 'resources/unsubscribe'
        handle_resources_unsubscribe(params, id)
      when nil
        # This is a notification response, we don't need to handle it
        nil
      else
        send_error(-32_601, "Method not found: #{method}", id)
      end
    rescue StandardError => e
      @logger.error("Error handling request: #{e.message}, #{e.backtrace.join("\n")}")
      send_error(-32_600, "Internal error: #{e.message}, #{e.backtrace.join("\n")}", id)
    end

    # Notify subscribers about a resource update
    def notify_resource_updated(uri)
      @logger.warn("Notifying subscribers about resource update: #{uri}, #{@resource_subscriptions.inspect}")
      return unless @client_initialized && @resource_subscriptions.key?(uri)

      resource = @resources[uri]
      notification = {
        jsonrpc: '2.0',
        method: 'notifications/resources/updated',
        params: {
          uri: uri,
          name: resource.name,
          mimeType: resource.mime_type
        }
      }

      @transport.send_message(notification)
    end

    def read_resource(uri)
      @resources.find { |r| r.match(uri) }
    end

    private

    PROTOCOL_VERSION = '2024-11-05'

    def handle_initialize(params, id)
      # Store client capabilities for later use
      @client_capabilities = params['capabilities'] || {}
      client_info = params['clientInfo'] || {}

      # Log client information
      @logger.info("Client connected: #{client_info['name']} v#{client_info['version']}")
      # @logger.debug("Client capabilities: #{client_capabilities.inspect}")

      # Prepare server response
      response = {
        protocolVersion: PROTOCOL_VERSION, # For now, only version 2024-11-05 is supported.
        capabilities: @capabilities,
        serverInfo: {
          name: @name,
          version: @version
        }
      }

      @logger.info("Server response: #{response.inspect}")

      send_result(response, id)
    end

    # Handle a resource read
    def handle_resources_read(params, id)
      uri = params['uri']

      return send_error(-32_602, 'Invalid params: missing resource URI', id) unless uri

      @logger.debug("Looking for resource with URI: #{uri}")

      begin
        resource = read_resource(uri)
        return send_error(-32_602, "Resource not found: #{uri}", id) unless resource

        @logger.debug("Found resource: #{resource.resource_name}, templated: #{resource.templated?}")

        base_content = { uri: uri }
        base_content[:mimeType] = resource.mime_type if resource.mime_type
        resource_instance = resource.initialize_from_uri(uri)
        @logger.debug("Resource instance params: #{resource_instance.params.inspect}")

        result = if resource_instance.binary?
                   {
                     contents: [base_content.merge(blob: Base64.strict_encode64(resource_instance.content))]
                   }
                 else
                   {
                     contents: [base_content.merge(text: resource_instance.content)]
                   }
                 end

        # # rescue StandardError => e
        # @logger.error("Error reading resource: #{e.message}")
        # @logger.error(e.backtrace.join("\n"))
        send_result(result, id)
      end
    end

    def handle_initialized_notification
      # The client is now ready for normal operation
      # No response needed for notifications
      @client_initialized = true
      @logger.info('Client initialized, beginning normal operation')

      nil
    end

    # Handle tools/list request
    def handle_tools_list(id)
      tools_list = @tools.values.map do |tool|
        {
          name: tool.tool_name,
          description: tool.description || '',
          inputSchema: tool.input_schema_to_json || { type: 'object', properties: {}, required: [] }
        }
      end

      send_result({ tools: tools_list }, id)
    end

    # Handle tools/call request
    def handle_tools_call(params, headers, id)
      tool_name = params['name']
      arguments = params['arguments'] || {}

      return send_error(-32_602, 'Invalid params: missing tool name', id) unless tool_name

      tool = @tools[tool_name]
      return send_error(-32_602, "Tool not found: #{tool_name}", id) unless tool

      begin
        # Convert string keys to symbols for Ruby
        symbolized_args = symbolize_keys(arguments)

        tool_instance = tool.new(headers: headers)
        authorized = tool_instance.authorized?(**symbolized_args)

        return send_error(-32_602, 'Unauthorized', id) unless authorized

        result, metadata = tool_instance.call_with_schema_validation!(**symbolized_args)

        # Format and send the result
        send_formatted_result(result, id, metadata)
      rescue FastMcp::Tool::InvalidArgumentsError => e
        @logger.error("Invalid arguments for tool #{tool_name}: #{e.message}")
        send_error_result(e.message, id)
      rescue StandardError => e
        @logger.error("Error calling tool #{tool_name}: #{e.message}")
        send_error_result("#{e.message}, #{e.backtrace.join("\n")}", id)
      end
    end

    # Format and send successful result
    def send_formatted_result(result, id, metadata)
      # Check if the result is already in the expected format
      if result.is_a?(Hash) && result.key?(:content)
        send_result(result, id, metadata: metadata)
      else
        # Format the result according to the MCP specification
        formatted_result = {
          content: [{ type: 'text', text: result.to_s }],
          isError: false
        }

        send_result(formatted_result, id, metadata: metadata)
      end
    end

    # Format and send error result
    def send_error_result(message, id)
      # Format error according to the MCP specification
      error_result = {
        content: [{ type: 'text', text: "Error: #{message}" }],
        isError: true
      }

      send_result(error_result, id)
    end

    # Handle resources/list request
    def handle_resources_list(id)
      resources_list = @resources.select(&:non_templated?).map(&:metadata)

      send_result({ resources: resources_list }, id)
    end

    # Handle resources/templates/list request
    def handle_resources_templates_list(id)
      # Collect templated resources
      templated_resources_list = @resources.select(&:templated?).map(&:metadata)

      send_result({ resourceTemplates: templated_resources_list }, id)
    end

    # Handle resources/subscribe request
    def handle_resources_subscribe(params, id)
      return unless @client_initialized

      uri = params['uri']

      unless uri
        send_error(-32_602, 'Invalid params: missing resource URI', id)
        return
      end

      resource = @resources.find { |r| r.match(uri) }
      return send_error(-32_602, "Resource not found: #{uri}", id) unless resource

      # Add to subscriptions
      @resource_subscriptions[uri] ||= []
      @resource_subscriptions[uri] << id

      send_result({ subscribed: true }, id)
    end

    # Handle resources/unsubscribe request
    def handle_resources_unsubscribe(params, id)
      return unless @client_initialized

      uri = params['uri']

      unless uri
        send_error(-32_602, 'Invalid params: missing resource URI', id)
        return
      end

      # Remove from subscriptions
      if @resource_subscriptions.key?(uri)
        @resource_subscriptions[uri].delete(id)
        @resource_subscriptions.delete(uri) if @resource_subscriptions[uri].empty?
      end

      send_result({ unsubscribed: true }, id)
    end

    # Notify clients about resource list changes
    def notify_resource_list_changed
      return unless @client_initialized

      notification = {
        jsonrpc: '2.0',
        method: 'notifications/resources/listChanged',
        params: {}
      }

      @transport.send_message(notification)
    end

    # Send a JSON-RPC result response
    def send_result(result, id, metadata: {})
      result[:_meta] = metadata if metadata.is_a?(Hash) && !metadata.empty?

      response = {
        jsonrpc: '2.0',
        id: id,
        result: result
      }

      @logger.info("Sending result: #{response.inspect}")
      send_response(response)
    end

    # Send a JSON-RPC error response
    def send_error(code, message, id = nil)
      response = {
        jsonrpc: '2.0',
        error: {
          code: code,
          message: message
        },
        id: id
      }

      send_response(response)
    end

    # Send a JSON-RPC response
    def send_response(response)
      if @transport
        @logger.debug("Sending response: #{response.inspect}")
        @transport.send_message(response)
      else
        @logger.warn("No transport available to send response: #{response.inspect}")
        @logger.warn("Transport: #{@transport.inspect}, transport_klass: #{@transport_klass.inspect}")
      end
    end

    # Helper method to convert string keys to symbols
    def symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
        result[new_key] = new_value
      end
    end
  end
end
