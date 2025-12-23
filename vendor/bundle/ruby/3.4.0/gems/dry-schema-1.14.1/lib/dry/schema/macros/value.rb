# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # A macro used for specifying predicates to be applied to values from a hash
      #
      # @api private
      class Value < DSL
        # @api private
        #
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def call(*args, **opts, &)
          types, predicates = args.partition { _1.is_a?(::Dry::Types::Type) }

          constructor = types.select { _1.is_a?(::Dry::Types::Constructor) }.reduce(:>>)
          schema = predicates.detect { _1.is_a?(Processor) }

          schema_dsl.set_type(name, constructor) if constructor

          type_spec = opts[:type_spec]

          if schema
            current_type = schema_dsl.types[name]

            updated_type =
              if array_type?(current_type)
                build_array_type(current_type, schema.strict_type_schema)
              else
                schema.strict_type_schema
              end

            import_steps(schema)

            if !custom_type? || array_type?(current_type) || hash_type?(current_type)
              type(updated_type)
            elsif maybe_type?(current_type)
              type(updated_type.optional)
            end
          end

          trace_opts = opts.except(:type_spec, :type_rule)

          if (type_rule = opts[:type_rule])
            trace.append(type_rule).evaluate(*predicates, **trace_opts)
            trace.append(new(chain: false).instance_exec(&)) if block_given?
          else
            trace.evaluate(*predicates, **trace_opts)

            if block_given? && type_spec.equal?(:hash)
              hash(&)
            elsif type_spec.is_a?(::Dry::Types::Type) && hash_type?(type_spec)
              hash(type_spec)
            elsif block_given?
              trace.append(new(chain: false).instance_exec(&))
            end
          end

          if trace.captures.empty?
            raise ArgumentError, "wrong number of arguments (given 0, expected at least 1)"
          end

          each(type_spec.type.member) if type_spec.respond_to?(:member)

          self
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        # @api private
        def array_type?(type)
          primitive_inferrer[type].eql?([::Array])
        end

        # @api private
        def hash_type?(type)
          primitive_inferrer[type].eql?([::Hash])
        end

        # @api private
        def maybe_type?(type)
          type.meta[:maybe].equal?(true)
        end

        # @api private
        def build_array_type(array_type, member)
          if array_type.respond_to?(:of)
            array_type.of(member)
          else
            raise ArgumentError, <<~ERROR.split("\n").join(" ")
              Cannot define schema for a nominal array type.
              Array types must be instances of Dry::Types::Array,
              usually constructed with Types::Constructor(Array) { ... } or
              Dry::Types['array'].constructor { ... }
            ERROR
          end
        end

        # @api private
        def import_steps(schema)
          schema_dsl.steps.import_callbacks(Path[[*path, name]], schema.steps)
        end

        # @api private
        def respond_to_missing?(meth, include_private = false)
          super || meth.to_s.end_with?(QUESTION_MARK)
        end

        private

        # @api private
        def method_missing(meth, ...)
          if meth.to_s.end_with?(QUESTION_MARK)
            trace.__send__(meth, ...)
          else
            super
          end
        end
      end
    end
  end
end
