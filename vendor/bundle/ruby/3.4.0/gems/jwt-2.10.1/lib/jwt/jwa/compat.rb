# frozen_string_literal: true

module JWT
  module JWA
    # Provides backwards compatibility for algorithms
    # @api private
    module Compat
      # @api private
      module ClassMethods
        def from_algorithm(algorithm)
          new(algorithm)
        end

        def sign(algorithm, msg, key)
          Deprecations.warning('Support for calling sign with positional arguments will be removed in future ruby-jwt versions')

          from_algorithm(algorithm).sign(data: msg, signing_key: key)
        end

        def verify(algorithm, key, signing_input, signature)
          Deprecations.warning('Support for calling verify with positional arguments will be removed in future ruby-jwt versions')

          from_algorithm(algorithm).verify(data: signing_input, signature: signature, verification_key: key)
        end
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end
    end
  end
end
