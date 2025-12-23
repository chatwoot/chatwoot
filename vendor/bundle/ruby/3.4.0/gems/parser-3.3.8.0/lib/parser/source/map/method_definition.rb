# frozen_string_literal: true

module Parser
  module Source

    class Map::MethodDefinition < Map
      attr_reader :keyword
      attr_reader :operator
      attr_reader :name
      attr_reader :end
      attr_reader :assignment

      def initialize(keyword_l, operator_l, name_l, end_l, assignment_l, body_l)
        @keyword  = keyword_l
        @operator = operator_l
        @name     = name_l
        @end      = end_l
        @assignment = assignment_l

        super(@keyword.join(end_l || body_l))
      end
    end

  end
end
