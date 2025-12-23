# frozen_string_literal: true

require 'jwt'

module OAuth2
  module Strategy
    # The Client Assertion Strategy
    #
    # @see https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-10#section-4.1.3
    #
    # Sample usage:
    #   client = OAuth2::Client.new(client_id, client_secret,
    #                               :site => 'http://localhost:8080',
    #                               :auth_scheme => :request_body)
    #
    #   claim_set = {
    #     :iss => "http://localhost:3001",
    #     :aud => "http://localhost:8080/oauth2/token",
    #     :sub => "me@example.com",
    #     :exp => Time.now.utc.to_i + 3600,
    #   }
    #
    #   encoding = {
    #     :algorithm => 'HS256',
    #     :key => 'secret_key',
    #   }
    #
    #   access = client.assertion.get_token(claim_set, encoding)
    #   access.token                 # actual access_token string
    #   access.get("/api/stuff")     # making api calls with access token in header
    #
    class Assertion < Base
      # Not used for this strategy
      #
      # @raise [NotImplementedError]
      def authorize_url
        raise(NotImplementedError, 'The authorization endpoint is not used in this strategy')
      end

      # Retrieve an access token given the specified client.
      #
      # @param [Hash] claims the hash representation of the claims that should be encoded as a JWT (JSON Web Token)
      #
      # For reading on JWT and claim keys:
      #   @see https://github.com/jwt/ruby-jwt
      #   @see https://datatracker.ietf.org/doc/html/rfc7519#section-4.1
      #   @see https://datatracker.ietf.org/doc/html/rfc7523#section-3
      #   @see https://www.iana.org/assignments/jwt/jwt.xhtml
      #
      # There are many possible claim keys, and applications may ask for their own custom keys.
      # Some typically required ones:
      #   :iss (issuer)
      #   :aud (audience)
      #   :sub (subject) -- formerly :prn https://datatracker.ietf.org/doc/html/draft-ietf-oauth-json-web-token-06#appendix-F
      #   :exp, (expiration time) -- in seconds, e.g. Time.now.utc.to_i + 3600
      #
      # Note that this method does *not* validate presence of those four claim keys indicated as required by RFC 7523.
      # There are endpoints that may not conform with this RFC, and this gem should still work for those use cases.
      #
      # @param [Hash] encoding_opts a hash containing instructions on how the JWT should be encoded
      # @option algorithm [String] the algorithm with which you would like the JWT to be encoded
      # @option key [Object] the key with which you would like to encode the JWT
      #
      # These two options are passed directly to `JWT.encode`.  For supported encoding arguments:
      #   @see https://github.com/jwt/ruby-jwt#algorithms-and-usage
      #   @see https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
      #
      # The object type of `:key` may depend on the value of `:algorithm`.  Sample arguments:
      #   get_token(claim_set, {:algorithm => 'HS256', :key => 'secret_key'})
      #   get_token(claim_set, {:algorithm => 'RS256', :key => OpenSSL::PKCS12.new(File.read('my_key.p12'), 'not_secret')})
      #
      # @param [Hash] request_opts options that will be used to assemble the request
      # @option request_opts [String] :scope the url parameter `scope` that may be required by some endpoints
      #   @see https://datatracker.ietf.org/doc/html/rfc7521#section-4.1
      #
      # @param [Hash] response_opts this will be merged with the token response to create the AccessToken object
      #   @see the access_token_opts argument to Client#get_token

      def get_token(claims, encoding_opts, request_opts = {}, response_opts = {})
        assertion = build_assertion(claims, encoding_opts)
        params = build_request(assertion, request_opts)

        @client.get_token(params, response_opts)
      end

    private

      def build_request(assertion, request_opts = {})
        {
          grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          assertion: assertion,
        }.merge(request_opts)
      end

      def build_assertion(claims, encoding_opts)
        raise ArgumentError.new(message: 'Please provide an encoding_opts hash with :algorithm and :key') if !encoding_opts.is_a?(Hash) || (%i[algorithm key] - encoding_opts.keys).any?

        JWT.encode(claims, encoding_opts[:key], encoding_opts[:algorithm])
      end
    end
  end
end
