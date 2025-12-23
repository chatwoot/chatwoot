# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # Macro specialization used within the DSL
      #
      # @api public
      class DSL < Core
        include ::Dry::Logic::Operators

        undef :eql?
        undef :nil?
        undef :respond_to?

        # @!attribute [r] chain
        #   Indicate if the macro should append its rules to the provided trace
        #   @return [Boolean]
        #   @api private
        option :chain, default: -> { true }

        # @!attribute [r] predicate_inferrer
        #   PredicateInferrer is used to infer predicate type-check from a type spec
        #   @return [PredicateInferrer]
        #   @api private
        option :predicate_inferrer, default: proc { PredicateInferrer.new(compiler.predicates) }

        # @!attribute [r] primitive_inferrer
        #   PrimitiveInferrer used to get a list of primitive classes from configured type
        #   @return [PrimitiveInferrer]
        #   @api private
        option :primitive_inferrer, default: proc { PrimitiveInferrer.new }

        # @overload value(*predicates, **predicate_opts)
        #   Set predicates without and with arguments
        #
        #   @param [Array<Symbol>] predicates
        #   @param [Hash] predicate_opts
        #
        #   @example with a predicate
        #     required(:name).value(:filled?)
        #
        #   @example with a predicate with arguments
        #     required(:name).value(min_size?: 2)
        #
        #   @example with a predicate with and without arguments
        #     required(:name).value(:filled?, min_size?: 2)
        #
        #   @example with a block
        #     required(:name).value { filled? & min_size?(2) }
        #
        # @return [Macros::Core]
        #
        # @api public
        def value(*args, **opts, &block)
          if (type_spec_from_opts = opts[:type_spec])
            append_macro(Macros::Value) do |macro|
              macro.call(*args, type_spec: type_spec_from_opts, **opts, &block)
            end
          else
            extract_type_spec(args) do |*predicates, type_spec:, type_rule:|
              append_macro(Macros::Value) do |macro|
                macro.call(*predicates, type_spec: type_spec, type_rule: type_rule, **opts, &block)
              end
            end
          end
        end

        # Prepends `:filled?` predicate
        #
        # @example with a type spec
        #   required(:name).filled(:string)
        #
        # @example with a type spec and a predicate
        #   required(:name).filled(:string, format?: /\w+/)
        #
        # @return [Macros::Core]
        #
        # @api public
        def filled(*args, **opts, &block)
          extract_type_spec(args) do |*predicates, type_spec:, type_rule:|
            append_macro(Macros::Filled) do |macro|
              macro.call(*predicates, type_spec: type_spec, type_rule: type_rule, **opts, &block)
            end
          end
        end

        # Set type specification and predicates for a maybe value
        #
        # @example
        #   required(:name).maybe(:string)
        #
        # @see Macros::Key#value
        #
        # @return [Macros::Key]
        #
        # @api public
        def maybe(*args, **opts, &block)
          extract_type_spec(args, nullable: true) do |*predicates, type_spec:, type_rule:|
            append_macro(Macros::Maybe) do |macro|
              macro.call(*predicates, type_spec: type_spec, type_rule: type_rule, **opts, &block)
            end
          end
        end

        # Specify a nested hash without enforced `hash?` type-check
        #
        # This is a simpler building block than `hash` macro, use it
        # when you want to provide `hash?` type-check with other rules
        # manually.
        #
        # @example
        #   required(:tags).value(:hash, min_size?: 1).schema do
        #     required(:name).value(:string)
        #   end
        #
        # @return [Macros::Core]
        #
        # @api public
        def schema(...)
          append_macro(Macros::Schema) do |macro|
            macro.call(...)
          end
        end

        # Specify a nested hash with enforced `hash?` type-check
        #
        # @example
        #   required(:tags).hash do
        #     required(:name).value(:string)
        #   end
        #
        # @api public
        def hash(...)
          append_macro(Macros::Hash) do |macro|
            macro.call(...)
          end
        end

        # Specify predicates that should be applied to each element of an array
        #
        # This is a simpler building block than `array` macro, use it
        # when you want to provide `array?` type-check with other rules
        # manually.
        #
        # @example a list of strings
        #   required(:tags).value(:array, min_size?: 2).each(:str?)
        #
        # @example a list of hashes
        #   required(:tags).value(:array, min_size?: 2).each(:hash) do
        #     required(:name).filled(:string)
        #   end
        #
        # @return [Macros::Core]
        #
        # @api public
        def each(...)
          append_macro(Macros::Each) do |macro|
            macro.value(...)
          end
        end

        # Like `each` but sets `array?` type-check
        #
        # @example a list of strings
        #   required(:tags).array(:str?)
        #
        # @example a list of hashes
        #   required(:tags).array(:hash) do
        #     required(:name).filled(:string)
        #   end
        #
        # @return [Macros::Core]
        #
        # @api public
        def array(...)
          append_macro(Macros::Array) do |macro|
            macro.value(...)
          end
        end

        # Set type spec
        #
        # @example
        #   required(:name).type(:string).value(min_size?: 2)
        #
        # @param [Symbol, Array, Dry::Types::Type] spec
        #
        # @return [Macros::Key]
        #
        # @api public
        def type(spec)
          schema_dsl.set_type(name, spec)
          self
        end

        # @api private
        def custom_type?
          schema_dsl.custom_type?(name)
        end

        private

        # @api private
        def append_macro(macro_type)
          macro = macro_type.new(schema_dsl: schema_dsl, name: name)

          yield(macro)

          if chain
            trace << macro
            self
          else
            macro
          end
        end

        # @api private
        # rubocop: disable Metrics/AbcSize
        # rubocop: disable Metrics/CyclomaticComplexity
        # rubocop: disable Metrics/PerceivedComplexity
        def extract_type_spec(args, nullable: false, set_type: true)
          type_spec = args[0] unless schema_or_predicate?(args[0])

          predicates = Array(type_spec ? args[1..] : args)
          type_rule = nil

          if type_spec
            resolved_type = resolve_type(type_spec, nullable)

            if type_spec.is_a?(::Array)
              type_rule = type_spec.map { |ts| new(chain: false).value(ts) }.reduce(:|)
            elsif type_spec.is_a?(Dry::Types::Sum) && set_type
              type_rule = [type_spec.left, type_spec.right].map { |ts|
                new(klass: Core, chain: false).value(ts)
              }.reduce(:|)
            else
              type_predicates = predicate_inferrer[resolved_type]

              predicates.replace(type_predicates + predicates) unless type_predicates.empty?

              return self if predicates.empty?
            end
          end

          type(resolved_type) if set_type && resolved_type

          if type_rule
            yield(*predicates, type_spec: nil, type_rule: type_rule)
          else
            yield(*predicates, type_spec: type_spec, type_rule: nil)
          end
        end
        # rubocop: enable Metrics/AbcSize
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/PerceivedComplexity

        # @api private
        def resolve_type(type_spec, nullable)
          resolved = schema_dsl.resolve_type(type_spec)

          if type_spec.is_a?(::Array) || !nullable || resolved.optional?
            resolved
          else
            schema_dsl.resolve_type([:nil, resolved])
          end
        end

        # @api private
        def schema_or_predicate?(arg)
          arg.is_a?(Dry::Schema::Processor) ||
            (arg.is_a?(Symbol) &&
              arg.to_s.end_with?(QUESTION_MARK))
        end
      end
    end
  end
end
