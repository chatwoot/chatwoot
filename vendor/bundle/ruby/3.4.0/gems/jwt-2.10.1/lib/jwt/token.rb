# frozen_string_literal: true

module JWT
  # Represents a JWT token
  #
  # Basic token signed using the HS256 algorithm:
  #
  #   token = JWT::Token.new(payload: {pay: 'load'})
  #   token.sign!(algorithm: 'HS256', key: 'secret')
  #   token.jwt # => eyJhb....
  #
  # Custom headers will be combined with generated headers:
  #   token = JWT::Token.new(payload: {pay: 'load'}, header: {custom: "value"})
  #   token.sign!(algorithm: 'HS256', key: 'secret')
  #   token.header # => {"custom"=>"value", "alg"=>"HS256"}
  #
  class Token
    include Claims::VerificationMethods

    # Initializes a new Token instance.
    #
    # @param header [Hash] the header of the JWT token.
    # @param payload [Hash] the payload of the JWT token.
    def initialize(payload:, header: {})
      @header  = header&.transform_keys(&:to_s)
      @payload = payload
    end

    # Returns the decoded signature of the JWT token.
    #
    # @return [String] the decoded signature of the JWT token.
    def signature
      @signature ||= ::JWT::Base64.url_decode(encoded_signature || '')
    end

    # Returns the encoded signature of the JWT token.
    #
    # @return [String] the encoded signature of the JWT token.
    def encoded_signature
      @encoded_signature ||= ::JWT::Base64.url_encode(signature)
    end

    # Returns the decoded header of the JWT token.
    #
    # @return [Hash] the header of the JWT token.
    attr_reader :header

    # Returns the encoded header of the JWT token.
    #
    # @return [String] the encoded header of the JWT token.
    def encoded_header
      @encoded_header ||= ::JWT::Base64.url_encode(JWT::JSON.generate(header))
    end

    # Returns the payload of the JWT token.
    #
    # @return [Hash] the payload of the JWT token.
    attr_reader :payload

    # Returns the encoded payload of the JWT token.
    #
    # @return [String] the encoded payload of the JWT token.
    def encoded_payload
      @encoded_payload ||= ::JWT::Base64.url_encode(JWT::JSON.generate(payload))
    end

    # Returns the signing input of the JWT token.
    #
    # @return [String] the signing input of the JWT token.
    def signing_input
      @signing_input ||= [encoded_header, encoded_payload].join('.')
    end

    # Returns the JWT token as a string.
    #
    # @return [String] the JWT token as a string.
    # @raise [JWT::EncodeError] if the token is not signed or other encoding issues
    def jwt
      @jwt ||= (@signature && [encoded_header, @detached_payload ? '' : encoded_payload, encoded_signature].join('.')) || raise(::JWT::EncodeError, 'Token is not signed')
    end

    # Detaches the payload according to https://datatracker.ietf.org/doc/html/rfc7515#appendix-F
    #
    def detach_payload!
      @detached_payload = true

      nil
    end

    # Signs the JWT token.
    #
    # @param algorithm [String, Object] the algorithm to use for signing.
    # @param key [String] the key to use for signing.
    # @return [void]
    # @raise [JWT::EncodeError] if the token is already signed or other problems when signing
    def sign!(algorithm:, key:)
      raise ::JWT::EncodeError, 'Token already signed' if @signature

      JWA.resolve(algorithm).tap do |algo|
        header.merge!(algo.header)
        @signature = algo.sign(data: signing_input, signing_key: key)
      end

      nil
    end

    # Returns the JWT token as a string.
    #
    # @return [String] the JWT token as a string.
    alias to_s jwt
  end
end
