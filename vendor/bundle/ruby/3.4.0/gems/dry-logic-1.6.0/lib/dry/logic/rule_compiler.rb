# frozen_string_literal: true

module Dry
  module Logic
    class RuleCompiler
      attr_reader :predicates

      def initialize(predicates)
        @predicates = predicates
      end

      def call(ast)
        ast.map { |node| visit(node) }
      end

      def visit(node)
        name, nodes = node
        send(:"visit_#{name}", nodes)
      end

      def visit_check(node)
        keys, predicate = node
        Operations::Check.new(visit(predicate), keys: keys)
      end

      def visit_not(node)
        Operations::Negation.new(visit(node))
      end

      def visit_key(node)
        name, predicate = node
        Operations::Key.new(visit(predicate), name: name)
      end

      def visit_attr(node)
        name, predicate = node
        Operations::Attr.new(visit(predicate), name: name)
      end

      def visit_set(node)
        Operations::Set.new(*call(node))
      end

      def visit_each(node)
        Operations::Each.new(visit(node))
      end

      def visit_predicate(node)
        name, params = node
        predicate = Rule::Predicate.build(predicates[name])

        if params.size > 1
          args = params.map(&:last).reject { |val| val == Undefined }
          predicate.curry(*args)
        else
          predicate
        end
      end

      def visit_and(node)
        left, right = node
        visit(left).and(visit(right))
      end

      def visit_or(node)
        left, right = node
        visit(left).or(visit(right))
      end

      def visit_xor(node)
        left, right = node
        visit(left).xor(visit(right))
      end

      def visit_implication(node)
        left, right = node
        visit(left).then(visit(right))
      end
    end
  end
end
