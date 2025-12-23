# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # Macro used to specify predicates for each element of an array
      #
      # @api private
      class Array < DSL
        # @api private
        # rubocop: disable Metrics/PerceivedComplexity
        # rubocop: disable Metrics/AbcSize
        def value(*args, **opts, &block)
          type(:array)

          extract_type_spec(args, set_type: false) do |*predicates, type_spec:, type_rule:|
            type(schema_dsl.array[type_spec]) if type_spec

            is_hash_block = type_spec.equal?(:hash)

            if predicates.any? || opts.any? || !is_hash_block
              super(
                *predicates, type_spec: type_spec, type_rule: type_rule, **opts,
                &(is_hash_block ? nil : block)
              )
            end

            is_op = args.size.equal?(2) && args[1].is_a?(Logic::Operations::Abstract)

            if is_hash_block && !is_op
              hash(&block)
            elsif is_op
              hash = Value.new(schema_dsl: schema_dsl.new, name: name).hash(args[1])

              trace.captures.concat(hash.trace.captures)

              type(schema_dsl.types[name].of(hash.schema_dsl.types[name]))
            end
          end

          self
        end
        # rubocop: enable Metrics/AbcSize
        # rubocop: enable Metrics/PerceivedComplexity

        # @api private
        def to_ast(*)
          [:and, [trace.array?.to_ast, [:each, trace.to_ast]]]
        end
        alias_method :ast, :to_ast
      end
    end
  end
end
