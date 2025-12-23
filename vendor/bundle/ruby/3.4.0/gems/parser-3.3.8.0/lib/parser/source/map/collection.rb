# frozen_string_literal: true

module Parser
  module Source

    class Map::Collection < Map
      attr_reader :begin
      attr_reader :end

      def initialize(begin_l, end_l, expression_l)
        @begin, @end = begin_l, end_l

        super(expression_l)
      end
    end

  end
end
