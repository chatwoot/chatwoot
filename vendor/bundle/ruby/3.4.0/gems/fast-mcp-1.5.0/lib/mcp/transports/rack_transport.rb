# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'rack'
require_relative 'base_transport'

module FastMcp
  module Transports
    # Rack middleware transport for MCP
    # This transport can be mounted in any Rack-compatible web framework
    class RackTransport < BaseTransport # rubocop:disable Metrics/ClassLength
      DEFAULT_PATH_PREFIX = '/mcp'
      DEFAULT_ALLOWED_ORIGINS = ['localhost', '127.0.0.1', '[::1]'].freeze
      DEFAULT_ALLOWED_IPS = ['127.0.0.1', '::1', '::ffff:127.0.0.1'].freeze
      SERVER_ENV_KEY = 'fast_mcp.server'

      SSE_HEADERS = {
        'Content-Type' => 'text/event-stream',
        'Cache-Control' => 'no-cache, no-store, must-revalidate',
        'Connection' => 'keep-alive',
        'X-Accel-Buffering' => 'no', # For Nginx
        'Access-Control-Allow-Origin' => '*', # Allow CORS
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => 'Content-Type',
        'Access-Control-Max-Age' => '86400', # 24 hours
        'Keep-Alive' => 'timeout=600', # 10 minutes timeout
        'Pragma' => 'no-cache',
        'Expires' => '0'
      }.freeze

      attr_reader :app, :path_prefix, :sse_clients, :messages_route, :sse_route, :allowed_origins, :localhost_only,
                  :allowed_ips

      def initialize(app, server, options = {}, &_block)
        super(server, logger: options[:logger])
        @app = app
        @path_prefix = options[:path_prefix] || DEFAULT_PATH_PREFIX
        @messages_route = options[:messages_route] || 'messages'
        @sse_route = options[:sse_route] || 'sse'
        @allowed_origins = options[:allowed_origins] || DEFAULT_ALLOWED_ORIGINS
        @localhost_only = options.fetch(:localhost_only, true) # Default to localhost-only mode
        @allowed_ips = options[:allowed_ips] || DEFAULT_ALLOWED_IPS
        @sse_clients = Concurrent::Hash.new
        @sse_clients_mutex = Mutex.new
        @running = false
        @filtered_servers_cache = {}
      end

      # Start the transport
      def start
        @logger.debug("Starting Rack transport with path prefix: #{@path_prefix}")
        @logger.debug("DNS rebinding protection enabled. Allowed origins: #{allowed_origins.join(', ')}")
        @running = true
      end

      # Stop the transport
      def stop
        @logger.debug('Stopping Rack transport')
        @running = false

        # Close all SSE connections
        @sse_clients_mutex.synchronize do
          @sse_clients.each_value do |client|
            client[:stream].close if client[:stream].respond_to?(:close) && !client[:stream].closed?
          rescue StandardError => e
            @logger.error("Error closing SSE connection: #{e.message}")
          end
          @sse_clients.clear
        end
      end

      # Send a message to all connected SSE clients
      def send_message(message)
        json_message = message.is_a?(String) ? message : JSON.generate(message)
        @logger.debug("Broadcasting message to #{@sse_clients.size} SSE clients: #{json_message}")

        clients_to_remove = []
        @sse_clients_mutex.synchronize do
          @sse_clients.each do |client_id, client|
            stream = client[:stream]
            mutex = client[:mutex]
            next if stream.nil? || (stream.respond_to?(:closed?) && stream.closed?) || mutex.nil?

            begin
              mutex.synchronize do
                stream.write("data: #{json_message}\n\n")
                stream.flush if stream.respond_to?(:flush)
              end
            rescue Errno::EPIPE, IOError => e
              @logger.info("Client #{client_id} disconnected: #{e.message}")
              clients_to_remove << client_id
            rescue StandardError => e
              @logger.error("Error sending message to client #{client_id}: #{e.message}")
              clients_to_remove << client_id
            end
          end
        end

        # Remove disconnected clients outside the loop to avoid modifying the hash during iteration
        clients_to_remove.each { |client_id| unregister_sse_client(client_id) }
      end

      # Register a new SSE client
      def register_sse_client(client_id, stream, mutex = nil)
        @sse_clients_mutex.synchronize do
          @logger.info("Registering SSE client: #{client_id}")
          @sse_clients[client_id] = { stream: stream, connected_at: Time.now, mutex: mutex || Mutex.new }
        end
      end

      # Unregister an SSE client
      def unregister_sse_client(client_id)
        @sse_clients_mutex.synchronize do
          @logger.info("Unregistering SSE client: #{client_id}")
          @sse_clients.delete(client_id)
        end
      end

      # Rack call method
      def call(env)
        request = Rack::Request.new(env)
        path = request.path
        @logger.debug("Rack request path: #{path}")

        # Check if the request is for our MCP endpoints
        if path.start_with?(@path_prefix)
          @logger.debug('Setting server transport to RackTransport')
          @server.transport = self
          handle_mcp_request(request, env)
        else
          # Pass through to the main application
          @app.call(env)
        end
      end

      private

      def validate_client_ip(request)
        client_ip = request.ip

        # Check if we're in localhost-only mode
        if @localhost_only && !@allowed_ips.include?(client_ip)
          @logger.warn("Blocked connection from non-localhost IP: #{client_ip}")
          return false
        end

        true
      end

      # Validate the Origin header to prevent DNS rebinding attacks
      def validate_origin(request, env)
        origin = env['HTTP_ORIGIN']

        # If no origin header is present, check the referer or host
        origin = env['HTTP_REFERER'] || request.host if origin.nil? || origin.empty?

        # Extract hostname from the origin
        hostname = extract_hostname(origin)

        # If we have a hostname and allowed_origins is not empty
        if hostname && !allowed_origins.empty?
          @logger.debug("Validating origin: #{hostname}")

          # Check if the hostname matches any allowed origin
          is_allowed = allowed_origins.any? do |allowed|
            if allowed.is_a?(Regexp)
              hostname.match?(allowed)
            else
              hostname == allowed
            end
          end

          unless is_allowed
            @logger.warn("Blocked request with origin: #{hostname}")
            return false
          end
        end

        true
      end

      # Extract hostname from a URL
      def extract_hostname(url)
        return nil if url.nil? || url.empty?

        begin
          # Check if the URL has a scheme, if not, add http:// as a prefix
          has_scheme = url.match?(%r{^[a-zA-Z][a-zA-Z0-9+.-]*://})
          parsing_url = has_scheme ? url : "http://#{url}"

          uri = URI.parse(parsing_url)

          # Return nil for invalid URLs where host is empty
          return nil if uri.host.nil? || uri.host.empty?

          uri.host
        rescue URI::InvalidURIError
          # If standard parsing fails, try to extract host with a regex for host:port format
          url.split(':').first if url.match?(%r{^([^:/]+)(:\d+)?$})
        end
      end

      # Handle MCP-specific requests
      def handle_mcp_request(request, env)
        # Validate client IP to ensure it's connecting from allowed sources
        return forbidden_response('Forbidden: Remote IP not allowed') unless validate_client_ip(request)

        # Validate Origin header to prevent DNS rebinding attacks
        return forbidden_response('Forbidden: Origin validation failed') unless validate_origin(request, env)

        # Get the appropriate server for this request
        request_server = get_server_for_request(request, env)

        # Store the current transport temporarily if using a filtered server
        if request_server != @server
          original_transport = request_server.transport
          request_server.transport = self
        end

        subpath = request.path[@path_prefix.length..]
        @logger.debug("MCP request subpath: '#{subpath.inspect}'")

        result = case subpath
                 when "/#{@sse_route}"
                   handle_sse_request(request, env)
                 when "/#{@messages_route}"
                   handle_message_request_with_server(request, request_server)
                 else
                   @logger.error('Received unknown request')
                   # Return 404 for unknown MCP endpoints
                   endpoint_not_found_response
                 end

        # Restore original transport if needed
        request_server.transport = original_transport if request_server != @server && original_transport

        result
      end

      def forbidden_response(message)
        [403, { 'Content-Type' => 'application/json' },
         [JSON.generate(
           {
             jsonrpc: '2.0',
             error: {
               code: -32_600,
               message: message
             },
             id: nil
           }
         )]]
      end

      # Return a 404 endpoint not found response
      def endpoint_not_found_response
        [404, { 'Content-Type' => 'application/json' },
         [JSON.generate(
           {
             jsonrpc: '2.0',
             error: {
               code: -32_601,
               message: 'Endpoint not found'
             },
             id: nil
           }
         )]]
      end

      # Handle SSE connection request
      def handle_sse_request(request, env)
        # Handle OPTIONS preflight request
        return [200, setup_cors_headers, []] if request.options?

        return method_not_allowed_response unless request.get?

        # Handle streaming based on the framework
        handle_streaming(env)
      end

      # Handle streaming based on the framework
      def handle_streaming(env)
        @logger.info("Handling streaming for env: #{env['HTTP_USER_AGENT']}")
        if env['rack.hijack']
          # Rack hijacking (e.g., Puma)
          @logger.info('Handling rack hijack SSE')
          handle_rack_hijack_sse(env)
        elsif rails_live_streaming?(env)
          # Rails ActionController::Live
          @logger.info('Handling rails live streaming SSE')
          handle_rails_sse(env)
        else
          # Fallback for servers that don't support streaming
          @logger.info('Falling back to default SSE')
          [200, SSE_HEADERS.dup, [":ok\n\n"]]
        end
      end

      # Check if Rails live streaming is available
      def rails_live_streaming?(env)
        defined?(ActionController::Live) &&
          env['action_controller.instance'].respond_to?(:response) &&
          env['action_controller.instance'].response.respond_to?(:stream)
      end

      # Set up CORS headers for preflight requests
      def setup_cors_headers
        {
          'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => 'GET, OPTIONS',
          'Access-Control-Allow-Headers' => 'Content-Type',
          'Access-Control-Max-Age' => '86400', # 24 hours
          'Content-Type' => 'text/plain'
        }
      end

      # Extract client ID from request or generate a new one
      def extract_client_id(env)
        request = Rack::Request.new(env)

        # Check various places for client ID
        client_id = request.params['client_id']
        client_id ||= env['HTTP_LAST_EVENT_ID']
        client_id ||= env['HTTP_X_CLIENT_ID']

        # Get browser information
        user_agent = env['HTTP_USER_AGENT'] || ''
        browser_type = detect_browser_type(user_agent)
        @logger.info("Client connection from: #{user_agent} (#{browser_type})")

        # Handle reconnection
        if client_id && @sse_clients.key?(client_id)
          handle_client_reconnection(client_id, browser_type)
        else
          # Generate a new client ID if none was provided
          client_id ||= SecureRandom.uuid
          @logger.info("New client connection: #{client_id} (#{browser_type})")
        end

        client_id
      end

      # Detect browser type from user agent
      def detect_browser_type(user_agent)
        is_chrome = user_agent.include?('Chrome/')
        is_safari = user_agent.include?('Safari/') && !user_agent.include?('Chrome/')
        is_firefox = user_agent.include?('Firefox/')
        is_node = user_agent.include?('Node.js') || user_agent.include?('node-fetch')

        if is_chrome
          'Chrome'
        elsif is_safari
          'Safari'
        elsif is_firefox
          'Firefox'
        elsif is_node
          'Node.js'
        else
          'Other browser'
        end
      end

      # Handle client reconnection
      def handle_client_reconnection(client_id, browser_type)
        @logger.info("Client #{client_id} is reconnecting (#{browser_type})")
        old_client = @sse_clients[client_id]
        begin
          old_client[:stream].close if old_client[:stream].respond_to?(:close) && !old_client[:stream].closed?
        rescue StandardError => e
          @logger.error("Error closing old connection for client #{client_id}: #{e.message}")
        end
        unregister_sse_client(client_id)

        # Small delay to ensure the old connection is fully closed
        sleep 0.1
      end

      # Handle SSE with Rack hijacking (e.g., Puma)
      def handle_rack_hijack_sse(env)
        client_id = extract_client_id(env)
        @logger.debug("Setting up Rack hijack SSE connection for client #{client_id}")

        env['rack.hijack'].call
        io = env['rack.hijack_io']
        @logger.debug("Obtained hijack IO for client #{client_id}")

        setup_sse_connection(client_id, io, env)
        start_keep_alive_thread(client_id, io)

        # Return async response
        [-1, {}, []]
      end

      # Set up the SSE connection
      def setup_sse_connection(client_id, io, env)
        # Handle for reconnection, if the client_id is already registered we reuse the mutex
        # If not a reconnection, generate a new mutex used in registration
        client = @sse_clients[client_id]
        mutex = client ? client[:mutex] : Mutex.new
        # Send headers
        @logger.debug("Sending HTTP headers for SSE connection #{client_id}")
        mutex.synchronize do
          io.write("HTTP/1.1 200 OK\r\n")
          SSE_HEADERS.each { |k, v| io.write("#{k}: #{v}\r\n") }
          io.write("\r\n")
          io.flush
        end

        # Register client (will overwrite if already present)
        register_sse_client(client_id, io, mutex)

        # Send an initial comment to keep the connection alive
        mutex.synchronize { io.write(": SSE connection established\n\n") }

        # Extract query parameters from the request
        query_string = env['QUERY_STRING']

        # Send endpoint information as the first message with query parameters
        endpoint = "#{@path_prefix}/#{@messages_route}"
        endpoint += "?#{query_string}" if query_string
        @logger.debug("Sending endpoint information to client #{client_id}: #{endpoint}")
        mutex.synchronize { io.write("event: endpoint\ndata: #{endpoint}\n\n") }

        # Send a retry directive with a very short reconnect time
        # This helps browsers reconnect quickly if the connection is lost
        mutex.synchronize do
          io.write("retry: 100\n\n")
          io.flush
        end
      rescue StandardError => e
        @logger.error("Error setting up SSE connection for client #{client_id}: #{e.message}")
        @logger.error(e.backtrace.join("\n")) if e.backtrace
        raise
      end

      # Start a keep-alive thread for SSE connection
      def start_keep_alive_thread(client_id, io)
        @logger.info("Starting keep-alive thread for client #{client_id}")
        Thread.new do
          keep_alive_loop(io, client_id)
        rescue StandardError => e
          @logger.error("Error in SSE keep-alive for client #{client_id}: #{e.message}")
          @logger.error(e.backtrace.join("\n")) if e.backtrace
        ensure
          cleanup_sse_connection(client_id, io)
        end
      end

      # Run the keep-alive loop
      def keep_alive_loop(io, client_id)
        @logger.info("Starting keep-alive loop for SSE connection #{client_id}")
        ping_count = 0
        ping_interval = 1 # Send a ping every 1 second
        @running = true
        mutex = @sse_clients[client_id] && @sse_clients[client_id][:mutex]
        while @running && !io.closed?
          begin
            mutex.synchronize { ping_count = send_keep_alive_ping(io, client_id, ping_count) }
            sleep ping_interval
          rescue Errno::EPIPE, IOError => e
            # Broken pipe or IO error - client disconnected
            @logger.error("SSE connection error for client #{client_id}: #{e.message}")
            break
          end
        end
      end

      # Send a keep-alive ping and return the updated ping count
      def send_keep_alive_ping(io, client_id, ping_count)
        ping_count += 1
        # Send a comment before each ping to keep the connection alive
        io.write(": keep-alive #{ping_count}\n\n")
        io.flush

        # Only send actual ping events every 5 counts to reduce overhead
        if (ping_count % 5).zero?
          @logger.debug("Sending ping ##{ping_count} to SSE client #{client_id}")
          send_ping_event(io)
        end
        ping_count
      end

      # Send a ping event
      def send_ping_event(io)
        ping_message = {
          jsonrpc: '2.0',
          method: 'ping',
          id: rand(1_000_000)
        }
        io.write("event: message\ndata: #{JSON.generate(ping_message)}\n\n")
        io.flush
      end

      # Clean up SSE connection
      def cleanup_sse_connection(client_id, io)
        @logger.info("Cleaning up SSE connection for client #{client_id}")
        mutex = @sse_clients[client_id] && @sse_clients[client_id][:mutex]
        unregister_sse_client(client_id)
        begin
          if mutex
            mutex.synchronize { io.close unless io.closed? }
          else
            io.close unless io.closed?
          end
          @logger.info("Successfully closed IO for client #{client_id}")
        rescue StandardError => e
          @logger.error("Error closing IO for client #{client_id}: #{e.message}")
        end
      end

      # Handle SSE with Rails ActionController::Live
      def handle_rails_sse(env)
        client_id = extract_client_id(env)
        controller = env['action_controller.instance']
        stream = controller.response.stream

        # Register client
        register_sse_client(client_id, stream)

        # The controller will handle the streaming
        [200, SSE_HEADERS, []]
      end

      # Handle message POST request with specific server
      def handle_message_request_with_server(request, server)
        @logger.debug('Received message request')
        return method_not_allowed_response unless request.post?

        begin
          process_json_request_with_server(request, server)
        rescue JSON::ParserError => e
          handle_parse_error(e)
        rescue StandardError => e
          handle_internal_error(e)
        end
      end

      def process_json_request_with_server(request, server)
        # Parse the request body
        body = request.body.read
        @logger.debug("Request body: #{body}")

        # Extract headers that might be relevant
        headers = request.env.select { |k, _v| k.start_with?('HTTP_') }
                         .transform_keys { |k| k.sub('HTTP_', '').downcase.tr('_', '-') }

        # Let the specific server handle the JSON request directly
        response = server.handle_request(body, headers: headers) || []

        # Return the JSON response
        [200, { 'Content-Type' => 'application/json' }, response]
      end

      # Return a method not allowed error response
      def method_not_allowed_response
        json_rpc_error_response(405, -32_601, 'Method not allowed')
      end

      # Handle JSON parse errors
      def handle_parse_error(error)
        @logger.error("Invalid JSON in request: #{error.message}")
        json_rpc_error_response(400, -32_700, 'Parse error: Invalid JSON')
      end

      # Handle internal server errors
      def handle_internal_error(error)
        @logger.error("Error processing message: #{error.message}")
        json_rpc_error_response(500, -32_603, "Internal error: #{error.message}")
      end

      def json_rpc_error_response(http_status, code, message, id = nil)
        [http_status, { 'Content-Type' => 'application/json' },
         [JSON.generate(
           {
             jsonrpc: '2.0',
             error: { code: code, message: message },
             id: id
           }
         )]]
      end

      # Get the appropriate server for this request
      def get_server_for_request(request, env)
        # 1. Check for explicit server in env (highest priority)
        if env[SERVER_ENV_KEY]
          @logger.debug("Using server from env[#{SERVER_ENV_KEY}]")
          return env[SERVER_ENV_KEY]
        end

        # 2. Apply filters if configured
        if @server.contains_filters?
          @logger.debug('Server has filters, creating filtered copy')
          # Cache filtered servers to avoid recreating them
          cache_key = generate_cache_key(request)

          @filtered_servers_cache[cache_key] ||= @server.create_filtered_copy(request)
          return @filtered_servers_cache[cache_key]
        end

        # 3. Use the default server
        @logger.debug('Using default server')
        @server
      end

      # Generate a cache key based on filter-relevant request attributes
      def generate_cache_key(request)
        # Generate a cache key based on filter-relevant request attributes
        # This is a simple example - real implementation would be more sophisticated
        {
          path: request.path,
          params: request.params.sort.to_h,
          headers: extract_relevant_headers(request)
        }.hash
      end

      # Extract headers that might be relevant for filtering
      def extract_relevant_headers(request)
        relevant_headers = {}
        ['X-User-Role', 'X-API-Version', 'X-Tenant-ID', 'Authorization'].each do |header|
          header_key = "HTTP_#{header.upcase.tr('-', '_')}"
          relevant_headers[header] = request.env[header_key] if request.env[header_key]
        end
        relevant_headers
      end
    end
  end
end
