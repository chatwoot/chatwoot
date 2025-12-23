# frozen_string_literal: true

module Parser
  module Source

    class Map::RescueBody < Map
      attr_reader :keyword
      attr_reader :assoc
      attr_reader :begin

      def initialize(keyword_l, assoc_l, begin_l, expression_l)
        @keyword = keyword_l
        @assoc   = assoc_l
        @begin   = begin_l

        super(expression_l)
      end
    end

  end
end
