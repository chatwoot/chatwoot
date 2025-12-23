# frozen_string_literal: true
module JMESPath
  # @api private
  module Nodes
    class Flatten < Node
      def initialize(child)
        @child = child
      end

      def visit(value)
        value = @child.visit(value)
        if value.respond_to?(:to_ary)
          value.to_ary.each_with_object([]) do |v, values|
            if v.respond_to?(:to_ary)
              values.concat(v.to_ary)
            else
              values.push(v)
            end
          end
        end
      end

      def optimize
        self.class.new(@child.optimize)
      end
    end
  end
end
