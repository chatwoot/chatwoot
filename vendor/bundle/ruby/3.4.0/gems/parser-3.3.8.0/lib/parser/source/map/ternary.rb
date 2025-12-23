# frozen_string_literal: true

module Parser
  module Source

    class Map::Ternary < Map
      attr_reader :question
      attr_reader :colon

      def initialize(question_l, colon_l, expression_l)
        @question, @colon = question_l, colon_l

        super(expression_l)
      end
    end

  end
end
