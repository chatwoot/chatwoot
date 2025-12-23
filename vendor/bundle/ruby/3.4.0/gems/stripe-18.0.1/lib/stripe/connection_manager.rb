# frozen_string_literal: true

module Stripe
  # Manages connections across multiple hosts which is useful because the
  # library may connect to multiple hosts during a typical session (main API,
  # Connect, Uploads). Ruby doesn't provide an easy way to make this happen
  # easily, so this class is designed to track what we're connected to and
  # manage the lifecycle of those connections.
  #
  # Note that this class in itself is *not* thread safe. We expect it to be
  # instantiated once per thread.
  class ConnectionManager
    # Timestamp (in seconds procured from the system's monotonic clock)
    # indicating when the connection manager last made a request. This is used
    # by `APIRequestor` to determine whether a connection manager should be
    # garbage collected or not.
    attr_reader :last_used
    attr_reader :config

    def initialize(config = Stripe.config)
      @config = config
      @active_connections = {}
      @last_used = Util.monotonic_time

      # A connection manager may be accessed across threads as one thread makes
      # requests on it while another is trying to clear it (either because it's
      # trying to garbage collect the manager or trying to clear it because a
      # configuration setting has changed). That's probably thread-safe already
      # because of Ruby's GIL, but just in case the library's running on JRuby
      # or the like, use a mutex to synchronize access in this connection
      # manager.
      @mutex = Mutex.new
    end

    # Finishes any active connections by closing their TCP connection and
    # clears them from internal tracking.
    def clear
      @mutex.synchronize do
        @active_connections.each_value(&:finish)
        @active_connections = {}
      end
    end

    # Gets a connection for a given URI. This is for internal use only as it's
    # subject to change (we've moved between HTTP client schemes in the past
    # and may do it again).
    #
    # `uri` is expected to be a string.
    def connection_for(uri)
      @mutex.synchronize do
        u = URI.parse(uri)
        connection = @active_connections[[u.host, u.port]]

        if connection.nil?
          connection = create_connection(u)
          connection.start

          @active_connections[[u.host, u.port]] = connection
        end

        connection
      end
    end

    # Executes an HTTP request to the given URI with the given method. Also
    # allows a request body, headers, and query string to be specified.
    def execute_request(method, uri, body: nil, headers: nil, query: nil,
                        &block)
      # Perform some basic argument validation because it's easy to get
      # confused between strings and hashes for things like body and query
      # parameters.
      raise ArgumentError, "method should be a symbol" \
        unless method.is_a?(Symbol)
      raise ArgumentError, "uri should be a string" \
        unless uri.is_a?(String)
      raise ArgumentError, "body should be a string" \
        if body && !body.is_a?(String)
      raise ArgumentError, "headers should be a hash" \
        if headers && !headers.is_a?(Hash)
      raise ArgumentError, "query should be a string" \
        if query && !query.is_a?(String)

      @last_used = Util.monotonic_time

      connection = connection_for(uri)

      u = URI.parse(uri)
      path = if query
               u.path + "?" + query
             else
               u.path
             end

      method_name = method.to_s.upcase
      has_response_body = method_name != "HEAD"
      request = Net::HTTPGenericRequest.new(
        method_name,
        (body ? true : false),
        has_response_body,
        path,
        headers
      )

      Util.log_debug("ConnectionManager starting request",
                     method_name: method_name,
                     path: path,
                     process_id: Process.pid,
                     thread_object_id: Thread.current.object_id,
                     connection_manager_object_id: object_id,
                     connection_object_id: connection.object_id,
                     log_timestamp: Util.monotonic_time)

      resp = @mutex.synchronize do
        # The block parameter is special here. If a block is provided, the block
        # is invoked with the Net::HTTPResponse. However, the body will not have
        # been read yet in the block, and can be streamed by calling
        # HTTPResponse#read_body.
        connection.request(request, body, &block)
      end

      Util.log_debug("ConnectionManager request complete",
                     method_name: method_name,
                     path: path,
                     process_id: Process.pid,
                     thread_object_id: Thread.current.object_id,
                     connection_manager_object_id: object_id,
                     connection_object_id: connection.object_id,
                     response_object_id: resp.object_id,
                     log_timestamp: Util.monotonic_time)

      resp
    end

    #
    # private
    #

    # `uri` should be a parsed `URI` object.
    private def create_connection(uri)
      # These all come back as `nil` if no proxy is configured.
      proxy_host, proxy_port, proxy_user, proxy_pass = proxy_parts

      connection = Net::HTTP.new(uri.host, uri.port,
                                 proxy_host, proxy_port,
                                 proxy_user, proxy_pass)

      # Time in seconds within which Net::HTTP will try to reuse an already
      # open connection when issuing a new operation. Outside this window, Ruby
      # will transparently close and re-open the connection without trying to
      # reuse it.
      #
      # Ruby's default of 2 seconds is almost certainly too short. Here I've
      # reused Go's default for `DefaultTransport`.
      connection.keep_alive_timeout = 30

      connection.open_timeout = config.open_timeout
      connection.read_timeout = config.read_timeout
      connection.write_timeout = config.write_timeout if connection.respond_to?(:write_timeout=)

      connection.use_ssl = uri.scheme == "https"

      if config.verify_ssl_certs
        connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
        connection.cert_store = config.ca_store
      else
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        warn_ssl_verify_none
      end

      connection
    end

    # `Net::HTTP` somewhat awkwardly requires each component of a proxy URI
    # (host, port, etc.) rather than the URI itself. This method simply parses
    # out those pieces to make passing them into a new connection a little less
    # ugly.
    private def proxy_parts
      if config.proxy.nil?
        [nil, nil, nil, nil]
      else
        u = URI.parse(config.proxy)
        [u.host, u.port, u.user, u.password]
      end
    end

    private def warn_ssl_verify_none
      return if @verify_ssl_warned

      @verify_ssl_warned = true
      warn("WARNING: Running without SSL cert verification. " \
           "You should never do this in production. " \
           "Execute `Stripe.verify_ssl_certs = true` to enable " \
           "verification.")
    end
  end
end
