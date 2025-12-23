# frozen_string_literal: true

module Dry
  module Types
    # Homogeneous mapping. It describes a hash with unknown keys that match a certain type.
    #
    # @example
    #   type = Dry::Types['hash'].map(
    #     Dry::Types['integer'].constrained(gteq: 1, lteq: 10),
    #     Dry::Types['string']
    #   )
    #
    #   type.(1 => 'right')
    #   # => {1 => 'right'}
    #
    #   type.('1' => 'wrong')
    #   # Dry::Types::MapError: "1" violates constraints (type?(Integer, "1")
    #   #                                                 AND gteq?(1, "1")
    #   #                                                 AND lteq?(10, "1") failed)
    #
    #   type.(11 => 'wrong')
    #   # Dry::Types::MapError: 11 violates constraints (lteq?(10, 11) failed)
    #
    # @api public
    class Map < Nominal
      def initialize(primitive, key_type: Types["any"], value_type: Types["any"], meta: EMPTY_HASH)
        super
      end

      # @return [Type]
      #
      # @api public
      def key_type = options[:key_type]

      # @return [Type]
      #
      # @api public
      def value_type = options[:value_type]

      # @return [String]
      #
      # @api public
      def name = "Map"

      # @param [Hash] hash
      #
      # @return [Hash]
      #
      # @api private
      def call_unsafe(hash)
        try(hash) { |failure|
          raise MapError, failure.error.message
        }.input
      end

      # @param [Hash] hash
      #
      # @return [Hash]
      #
      # @api private
      def call_safe(hash) = try(hash) { return yield }.input

      # @param [Hash] hash
      #
      # @return [Result]
      #
      # @api public
      def try(hash)
        result = coerce(hash)
        return result if result.success? || !block_given?

        yield(result)
      end

      # @param meta [Boolean] Whether to dump the meta to the AST
      #
      # @return [Array] An AST representation
      #
      # @api public
      def to_ast(meta: true)
        [:map,
         [key_type.to_ast(meta: true),
          value_type.to_ast(meta: true),
          meta ? self.meta : EMPTY_HASH]]
      end

      # @return [Boolean]
      #
      # @api public
      def constrained? = value_type.constrained?

      private

      # @api private
      # rubocop:disable Metrics/AbcSize
      def coerce(input)
        assert_primitive(input) do
          output = {}
          failures = []

          input.each do |k, v|
            res_k = key_type.try(k)
            res_v = value_type.try(v)

            if res_k.failure?
              failures << res_k.error
            elsif output.key?(res_k.input)
              failures << CoercionError.new("duplicate coerced hash key #{res_k.input.inspect}")
            elsif res_v.failure?
              failures << res_v.error
            else
              output[res_k.input] = res_v.input
            end
          end

          if failures.empty?
            success(output)
          else
            failure(input, MultipleError.new(failures))
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      def assert_primitive(input)
        if primitive?(input)
          yield
        else
          failure(input, CoercionError.new("#{input.inspect} must be an instance of #{primitive}"))
        end
      end
    end
  end
end
