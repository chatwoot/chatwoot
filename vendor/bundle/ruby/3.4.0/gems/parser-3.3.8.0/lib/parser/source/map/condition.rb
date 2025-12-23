# frozen_string_literal: true

module Parser
  module Source

    class Map::Condition < Map
      attr_reader :keyword
      attr_reader :begin
      attr_reader :else
      attr_reader :end

      def initialize(keyword_l, begin_l, else_l, end_l, expression_l)
        @keyword = keyword_l
        @begin, @else, @end = begin_l, else_l, end_l

        super(expression_l)
      end
    end

  end
end
