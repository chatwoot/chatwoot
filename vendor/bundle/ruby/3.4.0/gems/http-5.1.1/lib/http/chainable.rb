# frozen_string_literal: true

require "base64"

require "http/headers"

module HTTP
  module Chainable
    # Request a get sans response body
    # @param uri
    # @option options [Hash]
    def head(uri, options = {})
      request :head, uri, options
    end

    # Get a resource
    # @param uri
    # @option options [Hash]
    def get(uri, options = {})
      request :get, uri, options
    end

    # Post to a resource
    # @param uri
    # @option options [Hash]
    def post(uri, options = {})
      request :post, uri, options
    end

    # Put to a resource
    # @param uri
    # @option options [Hash]
    def put(uri, options = {})
      request :put, uri, options
    end

    # Delete a resource
    # @param uri
    # @option options [Hash]
    def delete(uri, options = {})
      request :delete, uri, options
    end

    # Echo the request back to the client
    # @param uri
    # @option options [Hash]
    def trace(uri, options = {})
      request :trace, uri, options
    end

    # Return the methods supported on the given URI
    # @param uri
    # @option options [Hash]
    def options(uri, options = {})
      request :options, uri, options
    end

    # Convert to a transparent TCP/IP tunnel
    # @param uri
    # @option options [Hash]
    def connect(uri, options = {})
      request :connect, uri, options
    end

    # Apply partial modifications to a resource
    # @param uri
    # @option options [Hash]
    def patch(uri, options = {})
      request :patch, uri, options
    end

    # Make an HTTP request with the given verb
    # @param (see Client#request)
    def request(*args)
      branch(default_options).request(*args)
    end

    # Prepare an HTTP request with the given verb
    # @param (see Client#build_request)
    def build_request(*args)
      branch(default_options).build_request(*args)
    end

    # @overload timeout(options = {})
    #   Adds per operation timeouts to the request
    #   @param [Hash] options
    #   @option options [Float] :read Read timeout
    #   @option options [Float] :write Write timeout
    #   @option options [Float] :connect Connect timeout
    # @overload timeout(global_timeout)
    #   Adds a global timeout to the full request
    #   @param [Numeric] global_timeout
    def timeout(options)
      klass, options = case options
                       when Numeric then [HTTP::Timeout::Global, {:global => options}]
                       when Hash    then [HTTP::Timeout::PerOperation, options.dup]
                       when :null   then [HTTP::Timeout::Null, {}]
                       else raise ArgumentError, "Use `.timeout(global_timeout_in_seconds)` or `.timeout(connect: x, write: y, read: z)`."

                       end

      %i[global read write connect].each do |k|
        next unless options.key? k

        options["#{k}_timeout".to_sym] = options.delete k
      end

      branch default_options.merge(
        :timeout_class   => klass,
        :timeout_options => options
      )
    end

    # @overload persistent(host, timeout: 5)
    #   Flags as persistent
    #   @param  [String] host
    #   @option [Integer] timeout Keep alive timeout
    #   @raise  [Request::Error] if Host is invalid
    #   @return [HTTP::Client] Persistent client
    # @overload persistent(host, timeout: 5, &block)
    #   Executes given block with persistent client and automatically closes
    #   connection at the end of execution.
    #
    #   @example
    #
    #       def keys(users)
    #         HTTP.persistent("https://github.com") do |http|
    #           users.map { |u| http.get("/#{u}.keys").to_s }
    #         end
    #       end
    #
    #       # same as
    #
    #       def keys(users)
    #         http = HTTP.persistent "https://github.com"
    #         users.map { |u| http.get("/#{u}.keys").to_s }
    #       ensure
    #         http.close if http
    #       end
    #
    #
    #   @yieldparam [HTTP::Client] client Persistent client
    #   @return [Object] result of last expression in the block
    def persistent(host, timeout: 5)
      options  = {:keep_alive_timeout => timeout}
      p_client = branch default_options.merge(options).with_persistent host
      return p_client unless block_given?

      yield p_client
    ensure
      p_client&.close
    end

    # Make a request through an HTTP proxy
    # @param [Array] proxy
    # @raise [Request::Error] if HTTP proxy is invalid
    def via(*proxy)
      proxy_hash = {}
      proxy_hash[:proxy_address]  = proxy[0] if proxy[0].is_a?(String)
      proxy_hash[:proxy_port]     = proxy[1] if proxy[1].is_a?(Integer)
      proxy_hash[:proxy_username] = proxy[2] if proxy[2].is_a?(String)
      proxy_hash[:proxy_password] = proxy[3] if proxy[3].is_a?(String)
      proxy_hash[:proxy_headers]  = proxy[2] if proxy[2].is_a?(Hash)
      proxy_hash[:proxy_headers]  = proxy[4] if proxy[4].is_a?(Hash)

      raise(RequestError, "invalid HTTP proxy: #{proxy_hash}") unless (2..5).cover?(proxy_hash.keys.size)

      branch default_options.with_proxy(proxy_hash)
    end
    alias through via

    # Make client follow redirects.
    # @param options
    # @return [HTTP::Client]
    # @see Redirector#initialize
    def follow(options = {})
      branch default_options.with_follow options
    end

    # Make a request with the given headers
    # @param headers
    def headers(headers)
      branch default_options.with_headers(headers)
    end

    # Make a request with the given cookies
    def cookies(cookies)
      branch default_options.with_cookies(cookies)
    end

    # Force a specific encoding for response body
    def encoding(encoding)
      branch default_options.with_encoding(encoding)
    end

    # Accept the given MIME type(s)
    # @param type
    def accept(type)
      headers Headers::ACCEPT => MimeType.normalize(type)
    end

    # Make a request with the given Authorization header
    # @param [#to_s] value Authorization header value
    def auth(value)
      headers Headers::AUTHORIZATION => value.to_s
    end

    # Make a request with the given Basic authorization header
    # @see http://tools.ietf.org/html/rfc2617
    # @param [#fetch] opts
    # @option opts [#to_s] :user
    # @option opts [#to_s] :pass
    def basic_auth(opts)
      user  = opts.fetch(:user)
      pass  = opts.fetch(:pass)
      creds = "#{user}:#{pass}"

      auth("Basic #{Base64.strict_encode64(creds)}")
    end

    # Get options for HTTP
    # @return [HTTP::Options]
    def default_options
      @default_options ||= HTTP::Options.new
    end

    # Set options for HTTP
    # @param opts
    # @return [HTTP::Options]
    def default_options=(opts)
      @default_options = HTTP::Options.new(opts)
    end

    # Set TCP_NODELAY on the socket
    def nodelay
      branch default_options.with_nodelay(true)
    end

    # Turn on given features. Available features are:
    # * auto_inflate
    # * auto_deflate
    # * instrumentation
    # * logging
    # * normalize_uri
    # @param features
    def use(*features)
      branch default_options.with_features(features)
    end

    private

    # :nodoc:
    def branch(options)
      HTTP::Client.new(options)
    end
  end
end
