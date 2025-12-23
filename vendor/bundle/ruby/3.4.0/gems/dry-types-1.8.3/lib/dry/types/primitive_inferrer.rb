# frozen_string_literal: true

module Dry
  module Types
    # PrimitiveInferrer returns the list of classes matching a type.
    #
    # @api public
    class PrimitiveInferrer
      extend Core::Cache

      # Compiler reduces type AST into a list of primitives
      #
      # @api private
      class Compiler
        # @api private
        def visit(node)
          meth, rest = node
          public_send(:"visit_#{meth}", rest)
        end

        # @api private
        def visit_nominal(node)
          type, _ = node
          type
        end

        # @api private
        def visit_hash(_) = ::Hash
        alias_method :visit_schema, :visit_hash

        # @api private
        def visit_array(_) = ::Array

        # @api private
        def visit_lax(node) = visit(node)

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
          left, right = node

          [visit(left), visit(right)].flatten(1)
        end

        # @api private
        def visit_constrained(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_any(_) = ::Object
      end

      # @return [Compiler]
      # @api private
      attr_reader :compiler

      # @api private
      def initialize
        @compiler = Compiler.new
      end

      # Infer primitives from the provided type
      #
      # @return [Array[Class]]
      #
      # @api private
      def [](type)
        self.class.fetch_or_store(type) do
          Array(compiler.visit(type.to_ast)).freeze
        end
      end
    end
  end
end
