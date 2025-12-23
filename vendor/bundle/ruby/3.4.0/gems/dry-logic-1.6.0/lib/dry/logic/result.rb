# frozen_string_literal: true

module Dry
  module Logic
    class Result
      SUCCESS = ::Class.new {
        def success?
          true
        end

        def failure?
          false
        end
      }.new.freeze

      attr_reader :success

      attr_reader :id

      attr_reader :serializer

      def initialize(success, id = nil, &block)
        @success = success
        @id = id
        @serializer = block
      end

      def success?
        success
      end

      def failure?
        !success?
      end

      def type
        success? ? :success : :failure
      end

      def ast(input = Undefined)
        serializer.(input)
      end

      def to_ast
        if id
          [type, [id, ast]]
        else
          ast
        end
      end

      def to_s
        visit(to_ast)
      end

      private

      def visit(ast)
        __send__(:"visit_#{ast[0]}", ast[1])
      end

      def visit_predicate(node)
        name, args = node

        if args.empty?
          name.to_s
        else
          "#{name}(#{args.map(&:last).map(&:inspect).join(", ")})"
        end
      end

      def visit_and(node)
        left, right = node
        "#{visit(left)} AND #{visit(right)}"
      end

      def visit_or(node)
        left, right = node
        "#{visit(left)} OR #{visit(right)}"
      end

      def visit_xor(node)
        left, right = node
        "#{visit(left)} XOR #{visit(right)}"
      end

      def visit_not(node)
        "not(#{visit(node)})"
      end

      def visit_hint(node)
        visit(node)
      end
    end
  end
end
