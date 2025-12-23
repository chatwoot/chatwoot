# frozen_string_literal: true

require 'openssl'

begin
  require 'rbnacl'
rescue LoadError
  raise if defined?(RbNaCl)
end

require_relative 'jwa/compat'
require_relative 'jwa/signing_algorithm'
require_relative 'jwa/ecdsa'
require_relative 'jwa/hmac'
require_relative 'jwa/none'
require_relative 'jwa/ps'
require_relative 'jwa/rsa'
require_relative 'jwa/unsupported'
require_relative 'jwa/wrapper'

require_relative 'jwa/eddsa' if JWT.rbnacl?

if JWT.rbnacl_6_or_greater?
  require_relative 'jwa/hmac_rbnacl'
elsif JWT.rbnacl?
  require_relative 'jwa/hmac_rbnacl_fixed'
end

module JWT
  # The JWA module contains all supported algorithms.
  module JWA
    class << self
      # @api private
      def resolve(algorithm)
        return find(algorithm) if algorithm.is_a?(String) || algorithm.is_a?(Symbol)

        unless algorithm.is_a?(SigningAlgorithm)
          Deprecations.warning('Custom algorithms are required to include JWT::JWA::SigningAlgorithm. Custom algorithms that do not include this module may stop working in the next major version of ruby-jwt.')
          return Wrapper.new(algorithm)
        end

        algorithm
      end

      # @api private
      def resolve_and_sort(algorithms:, preferred_algorithm:)
        algs = Array(algorithms).map { |alg| JWA.resolve(alg) }
        algs.partition { |alg| alg.valid_alg?(preferred_algorithm) }.flatten
      end

      # @deprecated The `::JWT::JWA.create` method is deprecated and will be removed in the next major version of ruby-jwt.
      def create(algorithm)
        Deprecations.warning('The ::JWT::JWA.create method is deprecated and will be removed in the next major version of ruby-jwt.')
        resolve(algorithm)
      end
    end
  end
end
