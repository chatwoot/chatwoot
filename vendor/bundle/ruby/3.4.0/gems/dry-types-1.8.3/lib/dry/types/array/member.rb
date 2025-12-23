# frozen_string_literal: true

module Dry
  module Types
    class Array < Nominal
      # Member arrays define their member type that is applied to each element
      #
      # @api public
      class Member < Array
        # @return [Type]
        attr_reader :member

        # @param [Class] primitive
        # @param [Hash] options
        #
        # @option options [Type] :member
        #
        # @api private
        def initialize(primitive, **options)
          @member = options.fetch(:member)
          super
        end

        # @param [Object] input
        #
        # @return [Array]
        #
        # @api private
        def call_unsafe(input)
          if primitive?(input)
            input.each_with_object([]) do |el, output|
              coerced = member.call_unsafe(el)

              output << coerced unless Undefined.equal?(coerced)
            end
          else
            super
          end
        end

        # @param [Object] input
        # @return [Array]
        #
        # @api private
        def call_safe(input)
          if primitive?(input)
            failed = false

            result = input.each_with_object([]) do |el, output|
              coerced = member.call_safe(el) { |out = el|
                failed = true
                out
              }

              output << coerced unless Undefined.equal?(coerced)
            end

            failed ? yield(result) : result
          else
            yield
          end
        end

        # @param [Array, Object] input
        # @param [#call,nil] block
        #
        # @yieldparam [Failure] failure
        # @yieldreturn [Result]
        #
        # @return [Result,Logic::Result]
        #
        # @api public
        def try(input, &block) # rubocop:disable Metrics/PerceivedComplexity
          if primitive?(input)
            output = []

            result = input.map { |el| member.try(el) }
            result.each do |r|
              output << r.input unless Undefined.equal?(r.input)
            end

            if result.all?(&:success?)
              success(output)
            else
              error = result.find(&:failure?).error
              failure = failure(output, error)
              block ? yield(failure) : failure
            end
          else
            failure = failure(input, CoercionError.new("#{input} is not an array"))
            block ? yield(failure) : failure
          end
        end

        # Build a lax type
        #
        # @return [Lax]
        #
        # @api public
        def lax
          Lax.new(Member.new(primitive, **options, member: member.lax, meta: meta))
        end

        # @see Nominal#to_ast
        #
        # @api public
        def to_ast(meta: true)
          if member.respond_to?(:to_ast)
            [:array, [member.to_ast(meta: meta), meta ? self.meta : EMPTY_HASH]]
          else
            [:array, [member, meta ? self.meta : EMPTY_HASH]]
          end
        end

        # @api private
        def constructor_type = ::Dry::Types::Array::Constructor
      end
    end
  end
end
