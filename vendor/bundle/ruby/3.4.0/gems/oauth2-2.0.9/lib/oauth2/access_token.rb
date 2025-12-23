# frozen_string_literal: true

module OAuth2
  class AccessToken # rubocop:disable Metrics/ClassLength
    TOKEN_KEYS_STR = %w[access_token id_token token accessToken idToken].freeze
    TOKEN_KEYS_SYM = %i[access_token id_token token accessToken idToken].freeze
    TOKEN_KEY_LOOKUP = TOKEN_KEYS_STR + TOKEN_KEYS_SYM

    attr_reader :client, :token, :expires_in, :expires_at, :expires_latency, :params
    attr_accessor :options, :refresh_token, :response

    class << self
      # Initializes an AccessToken from a Hash
      #
      # @param [Client] client the OAuth2::Client instance
      # @param [Hash] hash a hash of AccessToken property values
      # @option hash [String, Symbol] 'access_token', 'id_token', 'token', :access_token, :id_token, or :token the access token
      # @return [AccessToken] the initialized AccessToken
      def from_hash(client, hash)
        fresh = hash.dup
        supported_keys = TOKEN_KEY_LOOKUP & fresh.keys
        key = supported_keys[0]
        extra_tokens_warning(supported_keys, key)
        token = fresh.delete(key)
        new(client, token, fresh)
      end

      # Initializes an AccessToken from a key/value application/x-www-form-urlencoded string
      #
      # @param [Client] client the OAuth2::Client instance
      # @param [String] kvform the application/x-www-form-urlencoded string
      # @return [AccessToken] the initialized AccessToken
      def from_kvform(client, kvform)
        from_hash(client, Rack::Utils.parse_query(kvform))
      end

    private

      # Having too many is sus, and may lead to bugs. Having none is fine (e.g. refresh flow doesn't need a token).
      def extra_tokens_warning(supported_keys, key)
        return if OAuth2.config.silence_extra_tokens_warning
        return if supported_keys.length <= 1

        warn("OAuth2::AccessToken.from_hash: `hash` contained more than one 'token' key (#{supported_keys}); using #{key.inspect}.")
      end
    end

    # Initialize an AccessToken
    #
    # @param [Client] client the OAuth2::Client instance
    # @param [String] token the Access Token value (optional, may not be used in refresh flows)
    # @param [Hash] opts the options to create the Access Token with
    # @option opts [String] :refresh_token (nil) the refresh_token value
    # @option opts [FixNum, String] :expires_in (nil) the number of seconds in which the AccessToken will expire
    # @option opts [FixNum, String] :expires_at (nil) the epoch time in seconds in which AccessToken will expire
    # @option opts [FixNum, String] :expires_latency (nil) the number of seconds by which AccessToken validity will be reduced to offset latency, @version 2.0+
    # @option opts [Symbol] :mode (:header) the transmission mode of the Access Token parameter value
    #    one of :header, :body or :query
    # @option opts [String] :header_format ('Bearer %s') the string format to use for the Authorization header
    # @option opts [String] :param_name ('access_token') the parameter name to use for transmission of the
    #    Access Token value in :body or :query transmission mode
    def initialize(client, token, opts = {})
      @client = client
      @token = token.to_s

      opts = opts.dup
      %i[refresh_token expires_in expires_at expires_latency].each do |arg|
        instance_variable_set("@#{arg}", opts.delete(arg) || opts.delete(arg.to_s))
      end
      no_tokens = (@token.nil? || @token.empty?) && (@refresh_token.nil? || @refresh_token.empty?)
      if no_tokens
        if @client.options[:raise_errors]
          error = Error.new(opts)
          raise(error)
        else
          warn('OAuth2::AccessToken has no token')
        end
      end
      # @option opts [Fixnum, String] :expires is deprecated
      @expires_in ||= opts.delete('expires')
      @expires_in &&= @expires_in.to_i
      @expires_at &&= convert_expires_at(@expires_at)
      @expires_latency &&= @expires_latency.to_i
      @expires_at ||= Time.now.to_i + @expires_in if @expires_in
      @expires_at -= @expires_latency if @expires_latency
      @options = {mode: opts.delete(:mode) || :header,
                  header_format: opts.delete(:header_format) || 'Bearer %s',
                  param_name: opts.delete(:param_name) || 'access_token'}
      @params = opts
    end

    # Indexer to additional params present in token response
    #
    # @param [String] key entry key to Hash
    def [](key)
      @params[key]
    end

    # Whether or not the token expires
    #
    # @return [Boolean]
    def expires?
      !!@expires_at
    end

    # Whether or not the token is expired
    #
    # @return [Boolean]
    def expired?
      expires? && (expires_at <= Time.now.to_i)
    end

    # Refreshes the current Access Token
    #
    # @return [AccessToken] a new AccessToken
    # @note options should be carried over to the new AccessToken
    def refresh(params = {}, access_token_opts = {})
      raise('A refresh_token is not available') unless refresh_token

      params[:grant_type] = 'refresh_token'
      params[:refresh_token] = refresh_token
      new_token = @client.get_token(params, access_token_opts)
      new_token.options = options
      if new_token.refresh_token
        # Keep it, if there is one
      else
        new_token.refresh_token = refresh_token
      end
      new_token
    end
    # A compatibility alias
    # @note does not modify the receiver, so bang is not the default method
    alias refresh! refresh

    # Convert AccessToken to a hash which can be used to rebuild itself with AccessToken.from_hash
    #
    # @return [Hash] a hash of AccessToken property values
    def to_hash
      params.merge(access_token: token, refresh_token: refresh_token, expires_at: expires_at)
    end

    # Make a request with the Access Token
    #
    # @param [Symbol] verb the HTTP request method
    # @param [String] path the HTTP URL path of the request
    # @param [Hash] opts the options to make the request with
    #   @see Client#request
    def request(verb, path, opts = {}, &block)
      configure_authentication!(opts)
      @client.request(verb, path, opts, &block)
    end

    # Make a GET request with the Access Token
    #
    # @see AccessToken#request
    def get(path, opts = {}, &block)
      request(:get, path, opts, &block)
    end

    # Make a POST request with the Access Token
    #
    # @see AccessToken#request
    def post(path, opts = {}, &block)
      request(:post, path, opts, &block)
    end

    # Make a PUT request with the Access Token
    #
    # @see AccessToken#request
    def put(path, opts = {}, &block)
      request(:put, path, opts, &block)
    end

    # Make a PATCH request with the Access Token
    #
    # @see AccessToken#request
    def patch(path, opts = {}, &block)
      request(:patch, path, opts, &block)
    end

    # Make a DELETE request with the Access Token
    #
    # @see AccessToken#request
    def delete(path, opts = {}, &block)
      request(:delete, path, opts, &block)
    end

    # Get the headers hash (includes Authorization token)
    def headers
      {'Authorization' => options[:header_format] % token}
    end

  private

    def configure_authentication!(opts)
      case options[:mode]
      when :header
        opts[:headers] ||= {}
        opts[:headers].merge!(headers)
      when :query
        opts[:params] ||= {}
        opts[:params][options[:param_name]] = token
      when :body
        opts[:body] ||= {}
        if opts[:body].is_a?(Hash)
          opts[:body][options[:param_name]] = token
        else
          opts[:body] += "&#{options[:param_name]}=#{token}"
        end
        # @todo support for multi-part (file uploads)
      else
        raise("invalid :mode option of #{options[:mode]}")
      end
    end

    def convert_expires_at(expires_at)
      Time.iso8601(expires_at.to_s).to_i
    rescue ArgumentError
      expires_at.to_i
    end
  end
end
