# frozen_string_literal: true

require 'faraday'
require 'logger'

module OAuth2
  ConnectionError = Class.new(Faraday::ConnectionFailed)
  TimeoutError = Class.new(Faraday::TimeoutError)

  # The OAuth2::Client class
  class Client # rubocop:disable Metrics/ClassLength
    RESERVED_PARAM_KEYS = %w[body headers params parse snaky].freeze

    attr_reader :id, :secret, :site
    attr_accessor :options
    attr_writer :connection

    # Instantiate a new OAuth 2.0 client using the
    # Client ID and Client Secret registered to your
    # application.
    #
    # @param [String] client_id the client_id value
    # @param [String] client_secret the client_secret value
    # @param [Hash] options the options to create the client with
    # @option options [String] :site the OAuth2 provider site host
    # @option options [String] :redirect_uri the absolute URI to the Redirection Endpoint for use in authorization grants and token exchange
    # @option options [String] :authorize_url ('/oauth/authorize') absolute or relative URL path to the Authorization endpoint
    # @option options [String] :token_url ('/oauth/token') absolute or relative URL path to the Token endpoint
    # @option options [Symbol] :token_method (:post) HTTP method to use to request token (:get, :post, :post_with_query_string)
    # @option options [Symbol] :auth_scheme (:basic_auth) HTTP method to use to authorize request (:basic_auth or :request_body)
    # @option options [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday with
    # @option options [FixNum] :max_redirects (5) maximum number of redirects to follow
    # @option options [Boolean] :raise_errors (true) whether or not to raise an OAuth2::Error on responses with 400+ status codes
    # @option options [Logger] :logger (::Logger.new($stdout)) which logger to use when OAUTH_DEBUG is enabled
    # @option options [Proc] :extract_access_token proc that takes the client and the response Hash and extracts the access token from the response (DEPRECATED)
    # @option options [Class] :access_token_class [Class] class of access token for easier subclassing OAuth2::AccessToken, @version 2.0+
    # @yield [builder] The Faraday connection builder
    def initialize(client_id, client_secret, options = {}, &block)
      opts = options.dup
      @id = client_id
      @secret = client_secret
      @site = opts.delete(:site)
      ssl = opts.delete(:ssl)
      warn('OAuth2::Client#initialize argument `extract_access_token` will be removed in oauth2 v3. Refactor to use `access_token_class`.') if opts[:extract_access_token]
      @options = {
        authorize_url: 'oauth/authorize',
        token_url: 'oauth/token',
        token_method: :post,
        auth_scheme: :basic_auth,
        connection_opts: {},
        connection_build: block,
        max_redirects: 5,
        raise_errors: true,
        logger: ::Logger.new($stdout),
        access_token_class: AccessToken,
      }.merge(opts)
      @options[:connection_opts][:ssl] = ssl if ssl
    end

    # Set the site host
    #
    # @param value [String] the OAuth2 provider site host
    def site=(value)
      @connection = nil
      @site = value
    end

    # The Faraday connection object
    def connection
      @connection ||=
        Faraday.new(site, options[:connection_opts]) do |builder|
          oauth_debug_logging(builder)
          if options[:connection_build]
            options[:connection_build].call(builder)
          else
            builder.request :url_encoded             # form-encode POST params
            builder.adapter Faraday.default_adapter  # make requests with Net::HTTP
          end
        end
    end

    # The authorize endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def authorize_url(params = {})
      params = (params || {}).merge(redirection_params)
      connection.build_url(options[:authorize_url], params).to_s
    end

    # The token endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def token_url(params = nil)
      connection.build_url(options[:token_url], params).to_s
    end

    # Makes a request relative to the specified site root.
    # Updated HTTP 1.1 specification (IETF RFC 7231) relaxed the original constraint (IETF RFC 2616),
    #   allowing the use of relative URLs in Location headers.
    # @see https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.2
    #
    # @param [Symbol] verb one of :get, :post, :put, :delete
    # @param [String] url URL path of request
    # @param [Hash] opts the options to make the request with
    # @option opts [Hash] :params additional query parameters for the URL of the request
    # @option opts [Hash, String] :body the body of the request
    # @option opts [Hash] :headers http request headers
    # @option opts [Boolean] :raise_errors whether or not to raise an OAuth2::Error on 400+ status
    #   code response for this request.  Will default to client option
    # @option opts [Symbol] :parse @see Response::initialize
    # @option opts [true, false] :snaky (true) @see Response::initialize
    # @yield [req] @see Faraday::Connection#run_request
    def request(verb, url, opts = {}, &block)
      response = execute_request(verb, url, opts, &block)

      case response.status
      when 301, 302, 303, 307
        opts[:redirect_count] ||= 0
        opts[:redirect_count] += 1
        return response if opts[:redirect_count] > options[:max_redirects]

        if response.status == 303
          verb = :get
          opts.delete(:body)
        end
        location = response.headers['location']
        if location
          full_location = response.response.env.url.merge(location)
          request(verb, full_location, opts)
        else
          error = Error.new(response)
          raise(error, "Got #{response.status} status code, but no Location header was present")
        end
      when 200..299, 300..399
        # on non-redirecting 3xx statuses, just return the response
        response
      when 400..599
        error = Error.new(response)
        raise(error) if opts.fetch(:raise_errors, options[:raise_errors])

        response
      else
        error = Error.new(response)
        raise(error, "Unhandled status code value of #{response.status}")
      end
    end

    # Initializes an AccessToken by making a request to the token endpoint
    #
    # @param params [Hash] a Hash of params for the token endpoint, except:
    #   @option params [Symbol] :parse @see Response#initialize
    #   @option params [true, false] :snaky (true) @see Response#initialize
    # @param access_token_opts [Hash] access token options, to pass to the AccessToken object
    # @param extract_access_token [Proc] proc that extracts the access token from the response (DEPRECATED)
    # @yield [req] @see Faraday::Connection#run_request
    # @return [AccessToken] the initialized AccessToken
    def get_token(params, access_token_opts = {}, extract_access_token = nil, &block)
      warn('OAuth2::Client#get_token argument `extract_access_token` will be removed in oauth2 v3. Refactor to use `access_token_class` on #initialize.') if extract_access_token
      extract_access_token ||= options[:extract_access_token]
      parse, snaky, params, headers = parse_snaky_params_headers(params)

      request_opts = {
        raise_errors: options[:raise_errors],
        parse: parse,
        snaky: snaky,
      }
      if options[:token_method] == :post

        # NOTE: If proliferation of request types continues we should implement a parser solution for Request,
        #       just like we have with Response.
        request_opts[:body] = if headers['Content-Type'] == 'application/json'
                                params.to_json
                              else
                                params
                              end

        request_opts[:headers] = {'Content-Type' => 'application/x-www-form-urlencoded'}
      else
        request_opts[:params] = params
        request_opts[:headers] = {}
      end
      request_opts[:headers].merge!(headers)
      response = request(http_method, token_url, request_opts, &block)

      # In v1.4.x, the deprecated extract_access_token option retrieves the token from the response.
      # We preserve this behavior here, but a custom access_token_class that implements #from_hash
      # should be used instead.
      if extract_access_token
        parse_response_legacy(response, access_token_opts, extract_access_token)
      else
        parse_response(response, access_token_opts)
      end
    end

    # The HTTP Method of the request
    # @return [Symbol] HTTP verb, one of :get, :post, :put, :delete
    def http_method
      http_meth = options[:token_method].to_sym
      return :post if http_meth == :post_with_query_string

      http_meth
    end

    # The Authorization Code strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.1
    def auth_code
      @auth_code ||= OAuth2::Strategy::AuthCode.new(self)
    end

    # The Implicit strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-26#section-4.2
    def implicit
      @implicit ||= OAuth2::Strategy::Implicit.new(self)
    end

    # The Resource Owner Password Credentials strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.3
    def password
      @password ||= OAuth2::Strategy::Password.new(self)
    end

    # The Client Credentials strategy
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.4
    def client_credentials
      @client_credentials ||= OAuth2::Strategy::ClientCredentials.new(self)
    end

    def assertion
      @assertion ||= OAuth2::Strategy::Assertion.new(self)
    end

    # The redirect_uri parameters, if configured
    #
    # The redirect_uri query parameter is OPTIONAL (though encouraged) when
    # requesting authorization. If it is provided at authorization time it MUST
    # also be provided with the token exchange request.
    #
    # Providing the :redirect_uri to the OAuth2::Client instantiation will take
    # care of managing this.
    #
    # @api semipublic
    #
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-4.1
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-4.2.1
    # @see https://datatracker.ietf.org/doc/html/rfc6749#section-10.6
    # @return [Hash] the params to add to a request or URL
    def redirection_params
      if options[:redirect_uri]
        {'redirect_uri' => options[:redirect_uri]}
      else
        {}
      end
    end

  private

    def parse_snaky_params_headers(params)
      params = params.map do |key, value|
        if RESERVED_PARAM_KEYS.include?(key)
          [key.to_sym, value]
        else
          [key, value]
        end
      end.to_h
      parse = params.key?(:parse) ? params.delete(:parse) : Response::DEFAULT_OPTIONS[:parse]
      snaky = params.key?(:snaky) ? params.delete(:snaky) : Response::DEFAULT_OPTIONS[:snaky]
      params = authenticator.apply(params)
      # authenticator may add :headers, and we remove them here
      headers = params.delete(:headers) || {}
      [parse, snaky, params, headers]
    end

    def execute_request(verb, url, opts = {})
      url = connection.build_url(url).to_s

      begin
        response = connection.run_request(verb, url, opts[:body], opts[:headers]) do |req|
          req.params.update(opts[:params]) if opts[:params]
          yield(req) if block_given?
        end
      rescue Faraday::ConnectionFailed => e
        raise ConnectionError, e
      rescue Faraday::TimeoutError => e
        raise TimeoutError, e
      end

      parse = opts.key?(:parse) ? opts.delete(:parse) : Response::DEFAULT_OPTIONS[:parse]
      snaky = opts.key?(:snaky) ? opts.delete(:snaky) : Response::DEFAULT_OPTIONS[:snaky]

      Response.new(response, parse: parse, snaky: snaky)
    end

    # Returns the authenticator object
    #
    # @return [Authenticator] the initialized Authenticator
    def authenticator
      Authenticator.new(id, secret, options[:auth_scheme])
    end

    def parse_response_legacy(response, access_token_opts, extract_access_token)
      access_token = build_access_token_legacy(response, access_token_opts, extract_access_token)

      return access_token if access_token

      if options[:raise_errors]
        error = Error.new(response)
        raise(error)
      end

      nil
    end

    def parse_response(response, access_token_opts)
      access_token_class = options[:access_token_class]
      data = response.parsed

      unless data.is_a?(Hash) && !data.empty?
        return unless options[:raise_errors]

        error = Error.new(response)
        raise(error)
      end

      build_access_token(response, access_token_opts, access_token_class)
    end

    # Builds the access token from the response of the HTTP call
    #
    # @return [AccessToken] the initialized AccessToken
    def build_access_token(response, access_token_opts, access_token_class)
      access_token_class.from_hash(self, response.parsed.merge(access_token_opts)).tap do |access_token|
        access_token.response = response if access_token.respond_to?(:response=)
      end
    end

    # Builds the access token from the response of the HTTP call with legacy extract_access_token
    #
    # @return [AccessToken] the initialized AccessToken
    def build_access_token_legacy(response, access_token_opts, extract_access_token)
      extract_access_token.call(self, response.parsed.merge(access_token_opts))
    rescue StandardError
      nil
    end

    def oauth_debug_logging(builder)
      builder.response :logger, options[:logger], bodies: true if ENV['OAUTH_DEBUG'] == 'true'
    end
  end
end
