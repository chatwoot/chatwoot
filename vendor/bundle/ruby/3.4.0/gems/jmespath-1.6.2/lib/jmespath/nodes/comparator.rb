# frozen_string_literal: true
module JMESPath
  # @api private
  module Nodes
    class Comparator < Node
      COMPARABLE_TYPES = [Numeric, String].freeze

      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def self.create(relation, left, right)
        type = begin
          case relation
          when '==' then Comparators::Eq
          when '!=' then Comparators::Neq
          when '>' then Comparators::Gt
          when '>=' then Comparators::Gte
          when '<' then Comparators::Lt
          when '<=' then Comparators::Lte
          end
        end
        type.new(left, right)
      end

      def visit(value)
        check(@left.visit(value), @right.visit(value))
      end

      def optimize
        self.class.new(@left.optimize, @right.optimize)
      end

      private

      def check(_left_value, _right_value)
        nil
      end

      def comparable?(left_value, right_value)
        COMPARABLE_TYPES.any? do |type|
          left_value.is_a?(type) && right_value.is_a?(type)
        end
      end
    end

    module Comparators
      class Eq < Comparator
        def check(left_value, right_value)
          Util.as_json(left_value) == Util.as_json(right_value)
        end
      end

      class Neq < Comparator
        def check(left_value, right_value)
          Util.as_json(left_value) != Util.as_json(right_value)
        end
      end

      class Gt < Comparator
        def check(left_value, right_value)
          left_value > right_value if comparable?(left_value, right_value)
        end
      end

      class Gte < Comparator
        def check(left_value, right_value)
          left_value >= right_value if comparable?(left_value, right_value)
        end
      end

      class Lt < Comparator
        def check(left_value, right_value)
          left_value < right_value if comparable?(left_value, right_value)
        end
      end

      class Lte < Comparator
        def check(left_value, right_value)
          left_value <= right_value if comparable?(left_value, right_value)
        end
      end
    end
  end
end
