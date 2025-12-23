# frozen_string_literal: true

module Parser
  module Source

    class Map::For < Map
      attr_reader :keyword, :in
      attr_reader :begin, :end

      def initialize(keyword_l, in_l, begin_l, end_l, expression_l)
        @keyword, @in = keyword_l, in_l
        @begin, @end  = begin_l, end_l

        super(expression_l)
      end
    end

  end
end
