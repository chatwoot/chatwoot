# frozen_string_literal: true

module Parser
  module Source

    class Map::Send < Map
      attr_reader :dot
      attr_reader :selector
      attr_reader :operator
      attr_reader :begin
      attr_reader :end

      def initialize(dot_l, selector_l, begin_l, end_l, expression_l)
        @dot         = dot_l
        @selector    = selector_l
        @begin, @end = begin_l, end_l

        super(expression_l)
      end

      ##
      # @api private
      #
      def with_operator(operator_l)
        with { |map| map.update_operator(operator_l) }
      end

      protected

      def update_operator(operator_l)
        @operator = operator_l
      end
    end

  end
end
