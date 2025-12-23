# frozen_string_literal: true

require 'forwardable'

module JWT
  module JWK
    # JSON Web Key Set (JWKS) representation
    # https://tools.ietf.org/html/rfc7517
    class Set
      include Enumerable
      extend Forwardable

      attr_reader :keys

      def initialize(jwks = nil, options = {}) # rubocop:disable Metrics/CyclomaticComplexity
        jwks ||= {}

        @keys = case jwks
                when JWT::JWK::Set # Simple duplication
                  jwks.keys
                when JWT::JWK::KeyBase # Singleton
                  [jwks]
                when Hash
                  jwks = jwks.transform_keys(&:to_sym)
                  [*jwks[:keys]].map { |k| JWT::JWK.new(k, nil, options) }
                when Array
                  jwks.map { |k| JWT::JWK.new(k, nil, options) }
                else
                  raise ArgumentError, 'Can only create new JWKS from Hash, Array and JWK'
                end
      end

      def export(options = {})
        { keys: @keys.map { |k| k.export(options) } }
      end

      def_delegators :@keys, :each, :size, :delete, :dig

      def select!(&block)
        return @keys.select! unless block

        self if @keys.select!(&block)
      end

      def reject!(&block)
        return @keys.reject! unless block

        self if @keys.reject!(&block)
      end

      def uniq!(&block)
        self if @keys.uniq!(&block)
      end

      def merge(enum)
        @keys += JWT::JWK::Set.new(enum.to_a).keys
        self
      end

      def union(enum)
        dup.merge(enum)
      end

      def add(key)
        @keys << JWT::JWK.new(key)
        self
      end

      def ==(other)
        other.is_a?(JWT::JWK::Set) && keys.sort == other.keys.sort
      end

      alias eql? ==
      alias filter! select!
      alias length size
      # For symbolic manipulation
      alias | union
      alias + union
      alias << add
    end
  end
end
