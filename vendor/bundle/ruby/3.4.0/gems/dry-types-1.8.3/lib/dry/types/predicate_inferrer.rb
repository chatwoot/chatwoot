# frozen_string_literal: true

module Dry
  module Types
    # PredicateInferrer returns the list of predicates used by a type.
    #
    # @api public
    class PredicateInferrer
      extend Core::Cache

      TYPE_TO_PREDICATE = {
        ::DateTime => :date_time?,
        ::Date => :date?,
        ::Time => :time?,
        ::FalseClass => :false?,
        ::Integer => :int?,
        ::Float => :float?,
        ::NilClass => :nil?,
        ::String => :str?,
        ::TrueClass => :true?,
        ::BigDecimal => :decimal?,
        ::Array => :array?
      }.freeze

      REDUCED_TYPES = {
        [[[:true?], [:false?]]] => %i[bool?]
      }.freeze

      HASH = %i[hash?].freeze

      ARRAY = %i[array?].freeze

      NIL = %i[nil?].freeze

      # Compiler reduces type AST into a list of predicates
      #
      # @api private
      class Compiler
        extend Core::ClassAttributes

        defines :infer_predicate_by_class_name
        infer_predicate_by_class_name nil

        # @return [PredicateRegistry]
        # @api private
        attr_reader :registry

        # @api private
        def initialize(registry)
          @registry = registry
        end

        # @api private
        def infer_predicate(type) # rubocop:disable Metrics/PerceivedComplexity
          pred = TYPE_TO_PREDICATE.fetch(type) do
            if type.name.nil? || self.class.infer_predicate_by_class_name.equal?(false)
              nil
            else
              candidate = :"#{type.name.split("::").last.downcase}?"

              if registry.key?(candidate)
                if self.class.infer_predicate_by_class_name
                  candidate
                else
                  raise ::KeyError, <<~MESSAGE
                    Automatic predicate inferring from class names is deprecated
                    and will be removed in dry-types 2.0.
                    Use `Dry::Types::PredicateInferrer::Compiler.infer_predicate_by_class_name true`
                    to restore the previous behavior
                    or `Dry::Types::PredicateInferrer::Compiler.infer_predicate_by_class_name false`
                    to explicitly opt-out (i.e. no exception + no inferring).
                    Note: for dry-schema and dry-validation use Dry::Schema::PredicateInferrer::Compiler.
                  MESSAGE
                end
              else
                nil
              end
            end
          end

          if pred.nil?
            EMPTY_ARRAY
          else
            [pred]
          end
        end

        # @api private
        def visit(node)
          meth, rest = node
          public_send(:"visit_#{meth}", rest)
        end

        # @api private
        def visit_nominal(node)
          type = node[0]
          predicate = infer_predicate(type)

          if !predicate.empty? && registry.key?(predicate[0])
            predicate
          else
            [type?: type]
          end
        end

        # @api private
        def visit_hash(_)
          HASH
        end
        alias_method :visit_schema, :visit_hash

        # @api private
        def visit_array(_)
          ARRAY
        end

        # @api private
        def visit_lax(node)
          visit(node)
        end

        # @api private
        def visit_constructor(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_enum(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_sum(node)
          left_node, right_node, = node
          left = visit(left_node)
          right = visit(right_node)

          if left.eql?(NIL) # rubocop:disable Lint/DeprecatedConstants
            right
          else
            [[left, right]]
          end
        end

        # @api private
        def visit_constrained(node)
          other, rules = node
          predicates = visit(rules)

          if predicates.empty?
            visit(other)
          else
            [*visit(other), *merge_predicates(predicates)]
          end
        end

        # @api private
        def visit_any(_) = EMPTY_ARRAY

        # @api private
        def visit_and(node)
          left, right = node
          visit(left) + visit(right)
        end

        # @api private
        def visit_predicate(node)
          pred, args = node

          if pred.equal?(:type?) || !registry.key?(pred)
            EMPTY_ARRAY
          else
            *curried, _ = args
            values = curried.map { |_, v| v }

            if values.empty?
              [pred]
            else
              [pred => values[0]]
            end
          end
        end

        # @api private
        def visit_map(_node)
          raise ::NotImplementedError, "map types are not supported yet"
        end

        private

        # @api private
        def merge_predicates(nodes)
          preds, merged = nodes.each_with_object([[], {}]) do |predicate, (ps, h)|
            if predicate.is_a?(::Hash)
              h.update(predicate)
            else
              ps << predicate
            end
          end

          merged.empty? ? preds : [*preds, merged]
        end
      end

      # @return [Compiler]
      # @api private
      attr_reader :compiler

      # @api private
      def initialize(registry = PredicateRegistry.new)
        @compiler = Compiler.new(registry)
      end

      # Infer predicate identifier from the provided type
      #
      # @param [Type] type
      # @return [Symbol]
      #
      # @api private
      def [](type)
        self.class.fetch_or_store(type) do
          predicates = compiler.visit(type.to_ast)

          if predicates.is_a?(::Hash)
            predicates
          else
            REDUCED_TYPES[predicates] || predicates
          end
        end
      end
    end
  end
end
