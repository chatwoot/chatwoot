# frozen_string_literal: true

require_relative '../jwk/kid_as_key_digest'
require_relative '../jwk/thumbprint'

module JWT
  module Configuration
    # @api private
    class JwkConfiguration
      def initialize
        self.kid_generator_type = :key_digest
      end

      def kid_generator_type=(value)
        self.kid_generator = case value
                             when :key_digest
                               JWT::JWK::KidAsKeyDigest
                             when :rfc7638_thumbprint
                               JWT::JWK::Thumbprint
                             else
                               raise ArgumentError, "#{value} is not a valid kid generator type."
                             end
      end

      attr_accessor :kid_generator
    end
  end
end
