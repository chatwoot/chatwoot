# frozen_string_literal: true

module Parser
  module Source

    class Map::Index < Map
      attr_reader :begin
      attr_reader :end
      attr_reader :operator

      def initialize(begin_l, end_l, expression_l)
        @begin, @end = begin_l, end_l
        @operator = nil

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
