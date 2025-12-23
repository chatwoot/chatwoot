# frozen_string_literal: true

module Faraday
  # Connection objects manage the default properties and the middleware
  # stack for fulfilling an HTTP request.
  #
  # @example
  #
  #   conn = Faraday::Connection.new 'http://httpbingo.org'
  #
  #   # GET http://httpbingo.org/nigiri
  #   conn.get 'nigiri'
  #   # => #<Faraday::Response>
  #
  class Connection
    # A Set of allowed HTTP verbs.
    METHODS = Set.new %i[get post put delete head patch options trace]
    USER_AGENT = "Faraday v#{VERSION}".freeze

    # @return [Hash] URI query unencoded key/value pairs.
    attr_reader :params

    # @return [Hash] unencoded HTTP header key/value pairs.
    attr_reader :headers

    # @return [String] a URI with the prefix used for all requests from this
    #   Connection. This includes a default host name, scheme, port, and path.
    attr_reader :url_prefix

    # @return [Faraday::RackBuilder] Builder for this Connection.
    attr_reader :builder

    # @return [Hash] SSL options.
    attr_reader :ssl

    # @return [Object] the parallel manager for this Connection.
    attr_reader :parallel_manager

    # Sets the default parallel manager for this connection.
    attr_writer :default_parallel_manager

    # @return [Hash] proxy options.
    attr_reader :proxy

    # Initializes a new Faraday::Connection.
    #
    # @param url [URI, String] URI or String base URL to use as a prefix for all
    #           requests (optional).
    # @param options [Hash, Faraday::ConnectionOptions]
    # @option options [URI, String] :url ('http:/') URI or String base URL
    # @option options [Hash<String => String>] :params URI query unencoded
    #                 key/value pairs.
    # @option options [Hash<String => String>] :headers Hash of unencoded HTTP
    #                 header key/value pairs.
    # @option options [Hash] :request Hash of request options.
    # @option options [Hash] :ssl Hash of SSL options.
    # @option options [Hash, URI, String] :proxy proxy options, either as a URL
    #                 or as a Hash
    # @option options [URI, String] :proxy[:uri]
    # @option options [String] :proxy[:user]
    # @option options [String] :proxy[:password]
    # @yield [self] after all setup has been done
    def initialize(url = nil, options = nil)
      options = ConnectionOptions.from(options)

      if url.is_a?(Hash) || url.is_a?(ConnectionOptions)
        options = Utils.deep_merge(options, url)
        url     = options.url
      end

      @parallel_manager = nil
      @headers = Utils::Headers.new
      @params  = Utils::ParamsHash.new
      @options = options.request
      @ssl = options.ssl
      @default_parallel_manager = options.parallel_manager
      @manual_proxy = nil

      @builder = options.builder || begin
        # pass an empty block to Builder so it doesn't assume default middleware
        options.new_builder(block_given? ? proc { |b| } : nil)
      end

      self.url_prefix = url || 'http:/'

      @params.update(options.params)   if options.params
      @headers.update(options.headers) if options.headers

      initialize_proxy(url, options)

      yield(self) if block_given?

      @headers[:user_agent] ||= USER_AGENT
    end

    def initialize_proxy(url, options)
      @manual_proxy = !!options.proxy
      @proxy =
        if options.proxy
          ProxyOptions.from(options.proxy)
        else
          proxy_from_env(url)
        end
    end

    # Sets the Hash of URI query unencoded key/value pairs.
    # @param hash [Hash]
    def params=(hash)
      @params.replace hash
    end

    # Sets the Hash of unencoded HTTP header key/value pairs.
    # @param hash [Hash]
    def headers=(hash)
      @headers.replace hash
    end

    extend Forwardable

    def_delegators :builder, :use, :request, :response, :adapter, :app

    # Closes the underlying resources and/or connections. In the case of
    # persistent connections, this closes all currently open connections
    # but does not prevent new connections from being made.
    def close
      app.close
    end

    # @!method get(url = nil, params = nil, headers = nil)
    # Makes a GET HTTP request without a body.
    # @!scope class
    #
    # @param url [String, URI, nil] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash, nil] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.get '/items', { page: 1 }, :accept => 'application/json'
    #
    #   # ElasticSearch example sending a body with GET.
    #   conn.get '/twitter/tweet/_search' do |req|
    #     req.headers[:content_type] = 'application/json'
    #     req.params[:routing] = 'kimchy'
    #     req.body = JSON.generate(query: {...})
    #   end
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method head(url = nil, params = nil, headers = nil)
    # Makes a HEAD HTTP request without a body.
    # @!scope class
    #
    # @param url [String, URI, nil] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash, nil] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.head '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method delete(url = nil, params = nil, headers = nil)
    # Makes a DELETE HTTP request without a body.
    # @!scope class
    #
    # @param url [String, URI, nil] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash, nil] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.delete '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method trace(url = nil, params = nil, headers = nil)
    # Makes a TRACE HTTP request without a body.
    # @!scope class
    #
    # @param url [String, URI, nil] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash, nil] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.connect '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!visibility private
    METHODS_WITH_QUERY.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url = nil, params = nil, headers = nil)
          run_request(:#{method}, url, nil, headers) do |request|
            request.params.update(params) if params
            yield request if block_given?
          end
        end
      RUBY
    end

    # @overload options()
    #   Returns current Connection options.
    #
    # @overload options(url, params = nil, headers = nil)
    #   Makes an OPTIONS HTTP request to the given URL.
    #   @param url [String, URI, nil] String base URL to sue as a prefix for all requests.
    #   @param params [Hash, nil] Hash of URI query unencoded key/value pairs.
    #   @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.options '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]
    def options(*args)
      return @options if args.empty?

      url, params, headers = *args
      run_request(:options, url, nil, headers) do |request|
        request.params.update(params) if params
        yield request if block_given?
      end
    end

    # @!method post(url = nil, body = nil, headers = nil)
    # Makes a POST HTTP request with a body.
    # @!scope class
    #
    # @param url [String, URI, nil] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param body [String, nil] body for the request.
    # @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.post '/items', data, content_type: 'application/json'
    #
    #   # Simple ElasticSearch indexing sample.
    #   conn.post '/twitter/tweet' do |req|
    #     req.headers[:content_type] = 'application/json'
    #     req.params[:routing] = 'kimchy'
    #     req.body = JSON.generate(user: 'kimchy', ...)
    #   end
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method put(url = nil, body = nil, headers = nil)
    # Makes a PUT HTTP request with a body.
    # @!scope class
    #
    # @param url [String, URI, nil] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param body [String, nil] body for the request.
    # @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.put '/products/123', data, content_type: 'application/json'
    #
    #   # Star a gist.
    #   conn.put 'https://api.github.com/gists/GIST_ID/star' do |req|
    #     req.headers['Accept'] = 'application/vnd.github+json'
    #     req.headers['Authorization'] = 'Bearer <YOUR-TOKEN>'
    #     req.headers['X-GitHub-Api-Version'] = '2022-11-28'
    #   end
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!visibility private
    METHODS_WITH_BODY.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url = nil, body = nil, headers = nil, &block)
          run_request(:#{method}, url, body, headers, &block)
        end
      RUBY
    end

    # Check if the adapter is parallel-capable.
    #
    # @yield if the adapter isn't parallel-capable, or if no adapter is set yet.
    #
    # @return [Object, nil] a parallel manager or nil if yielded
    # @api private
    def default_parallel_manager
      @default_parallel_manager ||= begin
        adapter = @builder.adapter.klass if @builder.adapter

        if support_parallel?(adapter)
          adapter.setup_parallel_manager
        elsif block_given?
          yield
        end
      end
    end

    # Determine if this Faraday::Connection can make parallel requests.
    #
    # @return [Boolean]
    def in_parallel?
      !!@parallel_manager
    end

    # Sets up the parallel manager to make a set of requests.
    #
    # @param manager [Object] The parallel manager that this Connection's
    #                Adapter uses.
    #
    # @yield a block to execute multiple requests.
    # @return [void]
    def in_parallel(manager = nil, &block)
      @parallel_manager = manager || default_parallel_manager do
        warn 'Warning: `in_parallel` called but no parallel-capable adapter ' \
             'on Faraday stack'
        warn caller[2, 10].join("\n")
        nil
      end
      return yield unless @parallel_manager

      if @parallel_manager.respond_to?(:execute)
        # Execute is the new method that is responsible for executing the block.
        @parallel_manager.execute(&block)
      else
        # TODO: Old behaviour, deprecate and remove in 3.0
        yield
        @parallel_manager.run
      end
    ensure
      @parallel_manager = nil
    end

    # Sets the Hash proxy options.
    #
    # @param new_value [Object]
    def proxy=(new_value)
      @manual_proxy = true
      @proxy = new_value ? ProxyOptions.from(new_value) : nil
    end

    def_delegators :url_prefix, :scheme, :scheme=, :host, :host=, :port, :port=
    def_delegator :url_prefix, :path, :path_prefix

    # Parses the given URL with URI and stores the individual
    # components in this connection. These components serve as defaults for
    # requests made by this connection.
    #
    # @param url [String, URI]
    # @param encoder [Object]
    #
    # @example
    #
    #   conn = Faraday::Connection.new { ... }
    #   conn.url_prefix = "https://httpbingo.org/api"
    #   conn.scheme      # => https
    #   conn.path_prefix # => "/api"
    #
    #   conn.get("nigiri?page=2") # accesses https://httpbingo.org/api/nigiri
    def url_prefix=(url, encoder = nil)
      uri = @url_prefix = Utils.URI(url)
      self.path_prefix = uri.path

      params.merge_query(uri.query, encoder)
      uri.query = nil

      with_uri_credentials(uri) do |user, password|
        set_basic_auth(user, password)
        uri.user = uri.password = nil
      end

      @proxy = proxy_from_env(url) unless @manual_proxy
    end

    def set_basic_auth(user, password)
      header = Faraday::Utils.basic_header_from(user, password)
      headers[Faraday::Request::Authorization::KEY] = header
    end

    # Sets the path prefix and ensures that it always has a leading
    # slash.
    #
    # @param value [String]
    #
    # @return [String] the new path prefix
    def path_prefix=(value)
      url_prefix.path = if value
                          value = "/#{value}" unless value[0, 1] == '/'
                          value
                        end
    end

    # Takes a relative url for a request and combines it with the defaults
    # set on the connection instance.
    #
    # @param url [String, URI, nil]
    # @param extra_params [Hash]
    #
    # @example
    #   conn = Faraday::Connection.new { ... }
    #   conn.url_prefix = "https://httpbingo.org/api?token=abc"
    #   conn.scheme      # => https
    #   conn.path_prefix # => "/api"
    #
    #   conn.build_url("nigiri?page=2")
    #   # => https://httpbingo.org/api/nigiri?token=abc&page=2
    #
    #   conn.build_url("nigiri", page: 2)
    #   # => https://httpbingo.org/api/nigiri?token=abc&page=2
    #
    def build_url(url = nil, extra_params = nil)
      uri = build_exclusive_url(url)

      query_values = params.dup.merge_query(uri.query, options.params_encoder)
      query_values.update(extra_params) if extra_params
      uri.query =
        if query_values.empty?
          nil
        else
          query_values.to_query(options.params_encoder)
        end

      uri
    end

    # Builds and runs the Faraday::Request.
    #
    # @param method [Symbol] HTTP method.
    # @param url [String, URI, nil] String or URI to access.
    # @param body [String, Hash, Array, nil] The request body that will eventually be converted to
    #             a string; middlewares can be used to support more complex types.
    # @param headers [Hash, nil] unencoded HTTP header key/value pairs.
    #
    # @return [Faraday::Response]
    def run_request(method, url, body, headers)
      unless METHODS.include?(method)
        raise ArgumentError, "unknown http method: #{method}"
      end

      request = build_request(method) do |req|
        req.options.proxy = proxy_for_request(url)
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        yield(req) if block_given?
      end

      builder.build_response(self, request)
    end

    # Creates and configures the request object.
    #
    # @param method [Symbol]
    #
    # @yield [Faraday::Request] if block given
    # @return [Faraday::Request]
    def build_request(method)
      Request.create(method) do |req|
        req.params  = params.dup
        req.headers = headers.dup
        req.options = options.dup
        yield(req) if block_given?
      end
    end

    # Build an absolute URL based on url_prefix.
    #
    # @param url [String, URI, nil]
    # @param params [Faraday::Utils::ParamsHash] A Faraday::Utils::ParamsHash to
    #               replace the query values
    #          of the resulting url (default: nil).
    #
    # @return [URI]
    def build_exclusive_url(url = nil, params = nil, params_encoder = nil)
      url = nil if url.respond_to?(:empty?) && url.empty?
      base = url_prefix.dup
      if url && !base.path.end_with?('/')
        base.path = "#{base.path}/" # ensure trailing slash
      end
      # Ensure relative url will be parsed correctly (such as `service:search` )
      url = "./#{url}" if url.respond_to?(:start_with?) && !url.start_with?('http://', 'https://', '/', './', '../')
      uri = url ? base + url : base
      if params
        uri.query = params.to_query(params_encoder || options.params_encoder)
      end
      uri.query = nil if uri.query && uri.query.empty?
      uri
    end

    # Creates a duplicate of this Faraday::Connection.
    #
    # @api private
    #
    # @return [Faraday::Connection]
    def dup
      self.class.new(build_exclusive_url,
                     headers: headers.dup,
                     params: params.dup,
                     builder: builder.dup,
                     ssl: ssl.dup,
                     request: options.dup)
    end

    # Yields username and password extracted from a URI if they both exist.
    #
    # @param uri [URI]
    # @yield [username, password] any username and password
    # @yieldparam username [String] any username from URI
    # @yieldparam password [String] any password from URI
    # @return [void]
    # @api private
    def with_uri_credentials(uri)
      return unless uri.user && uri.password

      yield(Utils.unescape(uri.user), Utils.unescape(uri.password))
    end

    def proxy_from_env(url)
      return if Faraday.ignore_env_proxy

      uri = nil
      case url
      when String
        uri = Utils.URI(url)
        uri = if uri.host.nil?
                find_default_proxy
              else
                URI.parse("#{uri.scheme}://#{uri.host}").find_proxy
              end
      when URI
        uri = url.find_proxy
      when nil
        uri = find_default_proxy
      end
      ProxyOptions.from(uri) if uri
    end

    def find_default_proxy
      uri = ENV.fetch('http_proxy', nil)
      return unless uri && !uri.empty?

      uri = "http://#{uri}" unless uri.match?(/^http/i)
      uri
    end

    def proxy_for_request(url)
      return proxy if @manual_proxy

      if url && Utils.URI(url).absolute?
        proxy_from_env(url)
      else
        proxy
      end
    end

    def support_parallel?(adapter)
      adapter.respond_to?(:supports_parallel?) && adapter&.supports_parallel?
    end
  end
end
