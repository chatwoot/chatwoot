# frozen_string_literal: true

require_relative 'jwa'

module JWT
  # The Encode class is responsible for encoding JWT tokens.
  class Encode
    # Initializes a new Encode instance.
    #
    # @param options [Hash] the options for encoding the JWT token.
    # @option options [Hash] :payload the payload of the JWT token.
    # @option options [Hash] :headers the headers of the JWT token.
    # @option options [String] :key the key used to sign the JWT token.
    # @option options [String] :algorithm the algorithm used to sign the JWT token.
    def initialize(options)
      @token     = Token.new(payload: options[:payload], header: options[:headers])
      @key       = options[:key]
      @algorithm = options[:algorithm]
    end

    # Encodes the JWT token and returns its segments.
    #
    # @return [String] the encoded JWT token.
    def segments
      @token.verify_claims!(:numeric)
      @token.sign!(algorithm: @algorithm, key: @key)
      @token.jwt
    end
  end
end
