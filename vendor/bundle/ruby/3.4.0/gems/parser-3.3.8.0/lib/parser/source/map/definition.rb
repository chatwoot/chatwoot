# frozen_string_literal: true

module Parser
  module Source

    class Map::Definition < Map
      attr_reader :keyword
      attr_reader :operator
      attr_reader :name
      attr_reader :end

      def initialize(keyword_l, operator_l, name_l, end_l)
        @keyword  = keyword_l
        @operator = operator_l
        @name     = name_l
        @end      = end_l

        super(@keyword.join(@end))
      end
    end

  end
end
