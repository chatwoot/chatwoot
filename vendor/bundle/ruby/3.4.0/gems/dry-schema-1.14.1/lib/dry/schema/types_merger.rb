# frozen_string_literal: true

module Dry
  module Schema
    # Combines multiple logical operations into a single type, taking into
    # account the type of logical operation (or, and, implication) and the
    # underlying types (schemas, nominals, etc.)
    #
    # @api private
    class TypesMerger
      attr_reader :type_registry

      # @api private
      class ValueMerger
        attr_reader :types_merger
        attr_reader :op_class
        attr_reader :old
        attr_reader :new

        # @api private
        def initialize(types_merger, op_class, old, new)
          @types_merger = types_merger
          @op_class = op_class
          @old = old
          @new = new
        end

        # @api private
        def call
          if op_class <= ::Dry::Logic::Operations::Or
            merge_or
          elsif op_class <= ::Dry::Logic::Operations::And
            merge_and
          elsif op_class <= ::Dry::Logic::Operations::Implication
            merge_implication
          else
            raise ::ArgumentError, <<~MESSAGE
              Can't merge operations, op_class=#{op_class}
            MESSAGE
          end
        end

        private

        # @api private
        def merge_or
          old | new
        end

        # @api private
        def merge_ordered
          return old if old == new

          unwrapped_old, old_rule = unwrap_type(old)
          unwrapped_new, new_rule = unwrap_type(new)

          type = merge_unwrapped_types(unwrapped_old, unwrapped_new)

          rule = [old_rule, new_rule].compact.reduce { op_class.new(_1, _2) }

          type = ::Dry::Types::Constrained.new(type, rule: rule) if rule

          type
        end

        alias_method :merge_and, :merge_ordered
        alias_method :merge_implication, :merge_ordered

        # @api private
        def merge_unwrapped_types(unwrapped_old, unwrapped_new)
          case [unwrapped_old, unwrapped_new]
          in ::Dry::Types::Schema, ::Dry::Types::Schema
            merge_schemas(unwrapped_old, unwrapped_new)
          in [::Dry::Types::AnyClass, _] | [::Dry::Types::Hash, ::Dry::Types::Schema]
            unwrapped_new
          in [::Dry::Types::Schema, ::Dry::Types::Hash] | [_, ::Dry::Types::AnyClass]
            unwrapped_old
          else
            merge_equivalent_types(unwrapped_old, unwrapped_new)
          end
        end

        # @api private
        def merge_schemas(unwrapped_old, unwrapped_new)
          types_merger.type_registry["hash"].schema(
            types_merger.call(
              op_class,
              unwrapped_old.name_key_map,
              unwrapped_new.name_key_map
            )
          )
        end

        # @api private
        def merge_equivalent_types(unwrapped_old, unwrapped_new)
          if unwrapped_old.primitive <= unwrapped_new.primitive
            unwrapped_new
          elsif unwrapped_new.primitive <= unwrapped_old.primitive
            unwrapped_old
          else
            raise ::ArgumentError, <<~MESSAGE
              Can't merge types, unwrapped_old=#{unwrapped_old.inspect}, unwrapped_new=#{unwrapped_new.inspect}
            MESSAGE
          end
        end

        # @api private
        def unwrap_type(type)
          rules = []

          loop do
            rules << type.rule if type.respond_to?(:rule)

            if type.optional?
              type = type.left.primitive?(nil) ? type.right : type.left
            elsif type.is_a?(::Dry::Types::Decorator)
              type = type.type
            else
              break
            end
          end

          [type, rules.reduce(:&)]
        end
      end

      def initialize(type_registry = TypeRegistry.new)
        @type_registry = type_registry
      end

      # @api private
      def call(op_class, lhs, rhs)
        lhs.merge(rhs) do |_k, old, new|
          ValueMerger.new(self, op_class, old, new).call
        end
      end
    end
  end
end
